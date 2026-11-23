import base64
import json
import os
import shutil
import tempfile
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class DeployStudioContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads((ROOT / "terraform" / "deploy-studio.json").read_text(encoding="utf-8"))

    def test_contract_identity_and_terraform_path(self) -> None:
        self.assertEqual(self.contract["schema_version"], 2)
        self.assertEqual(self.contract["project_id"], "oracle-ai-accelerator")
        terraform_path = ROOT / self.contract["terraform"]["path"]
        self.assertTrue(terraform_path.is_dir())
        self.assertTrue(any(terraform_path.glob("*.tf")))
        self.assertEqual(self.contract["execution_source"], "oci_resource_manager")
        fields = {field["name"] for field in self.contract["form"]["fields"]}
        self.assertFalse(fields & {"source_ref", "source_commit_sha", "application_username"})
        credentials, services, *_ = self.contract["form"]["groups"]
        self.assertEqual(credentials["id"], "credentials")
        self.assertEqual([item["name"] for item in credentials["items"]], ["oci_config", "oci_key"])
        self.assertEqual(services["title"], "Services to deploy")
        self.assertEqual(services["items"][0]["name"], "oci_region")
        self.assertEqual(self.contract["capabilities"]["region_selection"], "config")

    def test_secrets_and_outputs_are_safe(self) -> None:
        password_fields = [field for field in self.contract["form"]["fields"] if field["type"] == "password"]
        self.assertTrue(password_fields)
        self.assertTrue(all(field.get("secret") is True for field in password_fields))
        forbidden = ("password", "secret", "private_key", "key_pem", "config")
        self.assertFalse(any(token in output.lower() for output in self.contract["outputs"] for token in forbidden))
        self.assertIsNone(self.contract["post_apply"])

    def test_default_resource_names_derive_from_deployment_suffix(self) -> None:
        naming = (ROOT / "terraform" / "naming.tf").read_text(encoding="utf-8")
        for legacy_override in ("bucket_name", "adb_db_name", "adb_display_name", "vcn_display_name", "instance_display_name"):
            self.assertIn(f'var.{legacy_override} != ""', naming)
        self.assertGreaterEqual(naming.count("var.deployment_suffix"), 5)

    def test_declares_all_deploy_studio_artifacts(self) -> None:
        self.assertEqual(
            set(self.contract["artifacts"]),
            {
                "adb_wallet.zip",
                "ssh-private-key.pem",
                "connection-summary.txt",
                "application-password.txt",
                "adb-admin-password.txt",
                "wallet-password.txt",
            },
        )

    def test_wallet_uses_a_private_bucket(self) -> None:
        bucket = (ROOT / "terraform" / "b_oci_objectstorage_bucket.tf").read_text(encoding="utf-8")
        self.assertRegex(bucket, r'access_type\s*=\s*"NoPublicAccess"')

    @unittest.skipUnless(shutil.which("terraform"), "Terraform CLI is required to render cloud-init")
    def test_cloud_init_renders_and_checks_out_the_selected_revision(self) -> None:
        template = ROOT / "terraform" / "templatefile" / "user_data.sh"
        with tempfile.TemporaryDirectory() as tmp:
            work = Path(tmp)
            repo = work / "source"
            repo.mkdir()

            def git(*args: str, cwd: Path = repo) -> str:
                return subprocess.run(
                    ["git", *args], cwd=cwd, check=True, capture_output=True, text=True,
                ).stdout.strip()

            git("init", "--initial-branch=main")
            commit_args = ("-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit")
            git(*commit_args, "--allow-empty", "-m", "selected release")
            sha = git("rev-parse", "HEAD")
            git(*commit_args, "--allow-empty", "-m", "newer main")
            data = {
                "bucket_name": "test-bucket",
                "oci_config_base64": "",
                "oci_key_base64": "",
                "source_repo_base64": base64.b64encode(repo.as_uri().encode()).decode(),
                "source_ref_base64": "bWFpbg==",
                "source_commit_sha": sha,
                "env_base64": "",
            }
            expression = f"base64encode(templatefile({json.dumps(template.as_posix())}, {json.dumps(data)}))"
            console = subprocess.run(
                ["terraform", "console", "-no-color"], cwd=work, input=expression + "\n",
                check=True, capture_output=True, text=True, timeout=30,
            )
            rendered = base64.b64decode(json.loads(console.stdout.strip())).decode()
            self.assertIn(f"SOURCE_COMMIT_SHA='{sha}'", rendered)

            bash = shutil.which("bash")
            if os.name == "nt":
                git_bash = Path("C:/Program Files/Git/bin/bash.exe")
                bash = str(git_bash) if git_bash.is_file() else None
            if not bash:
                self.skipTest("Bash is required to exercise the rendered checkout")
            cloud_init = work / "user_data.sh"
            cloud_init.write_text(rendered, encoding="utf-8", newline="\n")
            subprocess.run([bash, "-n", cloud_init.as_posix()], check=True)
            lines = rendered.splitlines()
            start = next(i for i, line in enumerate(lines) if line.startswith("SOURCE_REPO_URL="))
            checkout_start = lines.index('if [ -n "$SOURCE_COMMIT_SHA" ]; then')
            checkout_end = lines.index('chown -R opc:opc "$CHECKOUT"')
            checkout_script = work / "checkout.sh"
            checkout_script.write_text(
                "\n".join(["set -eu", *lines[start:start + 3], 'CHECKOUT="$1"', *lines[checkout_start:checkout_end]]) + "\n",
                encoding="utf-8", newline="\n",
            )
            checkout = work / "deployed-app"
            subprocess.run([bash, checkout_script.as_posix(), checkout.as_posix()], check=True)
            self.assertEqual(git("rev-parse", "HEAD", cwd=checkout), sha)

    def test_local_environment_file_is_not_versioned(self) -> None:
        tracked = subprocess.run(
            ["git", "ls-files", "--", "app/.env"],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(tracked.stdout.strip(), "")
        self.assertTrue((ROOT / "app" / ".env.example").is_file())


if __name__ == "__main__":
    unittest.main()
