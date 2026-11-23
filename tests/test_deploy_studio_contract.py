import base64
import io
import json
import os
import shutil
import sys
import tempfile
import subprocess
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]


def find_bash() -> str | None:
    if os.name == "nt":
        git_bash = Path("C:/Program Files/Git/bin/bash.exe")
        return str(git_bash) if git_bash.is_file() else None
    return shutil.which("bash")


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
        self.assertEqual(set(self.contract["artifacts"]), {"adb_wallet.zip", "ssh-private-key.pem"})

    def test_email_access_follows_form_order(self) -> None:
        email = self.contract["email"]
        database, application = email["services"]
        self.assertEqual([database["title"], application["title"]], ["Autonomous Database", "Application VM"])
        self.assertEqual(database["fields"], [
            {"label": "User", "value": "ADMIN"},
            {"label": "Password", "input": "autonomous_database_admin_password"},
            {"label": "Wallet Password", "input": "autonomous_database_wallet_password"},
        ])
        self.assertEqual(application["fields"], [
            {"label": "Access URL", "output": "application_url", "link": True},
            {"label": "User", "value": "admin"},
            {"label": "Password", "input": "autonomous_database_developer_password"},
        ])
        self.assertEqual(self.contract["form"]["email_access_fields"], [
            field["input"] for service in email["services"] for field in service["fields"] if "input" in field
        ])
        self.assertEqual(email["attachments"], [
            "adb_wallet.zip", "ssh-private-key.pem", "deployment.log", "resource-manager-terraform-source.zip",
        ])

    def test_application_files_use_a_private_bucket(self) -> None:
        bucket = (ROOT / "terraform" / "b_oci_objectstorage_bucket.tf").read_text(encoding="utf-8")
        self.assertRegex(bucket, r'access_type\s*=\s*"NoPublicAccess"')

    def test_bootstrap_downloads_the_wallet_from_the_selected_database(self) -> None:
        template = (ROOT / "terraform" / "templatefile" / "user_data.sh").read_text(encoding="utf-8")
        script = template.split('<<\'PY_WALLET\'\n', 1)[1].split("\nPY_WALLET\n", 1)[0]
        terraform = (ROOT / "terraform" / "c_oci_database_autonomous_database.tf").read_text(encoding="utf-8")
        self.assertNotIn('resource "oci_objectstorage_object" "adb_wallet_zip"', terraform)
        self.assertIn('resource "oci_database_autonomous_database_wallet" "adb_wallet"', terraform)

        wallet = io.BytesIO()
        with ZipFile(wallet, "w") as archive:
            archive.writestr("tnsnames.ora", "synthetic wallet")
        payload = wallet.getvalue()
        selected_database = "ocid1.autonomousdatabase.oc1.example"
        selected_region = "us-chicago-1"
        wallet_password = "synthetic-wallet-password"
        new_client = Mock()
        new_client.return_value.generate_autonomous_database_wallet.return_value = SimpleNamespace(
            data=SimpleNamespace(content=payload)
        )
        retry = object()
        oci = SimpleNamespace(
            config=SimpleNamespace(from_file=Mock(return_value={"region": "other-region"})),
            database=SimpleNamespace(
                DatabaseClient=new_client,
                models=SimpleNamespace(GenerateAutonomousDatabaseWalletDetails=dict),
            ),
            retry=SimpleNamespace(DEFAULT_RETRY_STRATEGY=retry),
        )
        dotenv = SimpleNamespace(dotenv_values=Mock(return_value={"CON_ADB_WALLET_PASSWORD": wallet_password}))

        with patch.dict(sys.modules, {"oci": oci, "dotenv": dotenv}), patch.object(
            sys, "argv", ["-", selected_database, selected_region]
        ), patch.object(Path, "write_bytes", autospec=True) as write_wallet:
            exec(compile(script, "<cloud-init wallet>", "exec"), {})

        oci.config.from_file.assert_called_once_with("/home/opc/.oci/config")
        new_client.assert_called_once_with({"region": selected_region}, timeout=(5, 40))
        new_client.return_value.generate_autonomous_database_wallet.assert_called_once_with(
            selected_database, {"password": wallet_password}, retry_strategy=retry
        )
        write_wallet.assert_called_once_with(Path("wallet/adb_wallet.zip"), payload)

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
                "adb_id": "ocid1.autonomousdatabase.oc1.example",
                "region": "us-chicago-1",
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

            bash = find_bash()
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

    def test_health_check_cron_handles_first_boot_and_preserves_existing_entries(self) -> None:
        bash = find_bash()
        if not bash:
            self.skipTest("Bash is required to exercise the cron setup")

        template = (ROOT / "terraform" / "templatefile" / "user_data.sh").read_text(encoding="utf-8")
        start = template.index("# Add cron job for health check")
        end = template.index("# Step 15: Install and configure Nginx", start)
        mock = r"""
set -euo pipefail
cron_file=$1
cron_mode=$2
crontab() {
  case "$3" in
    -l)
      if [[ "$cron_mode" == "denied" ]]; then
        echo "Permission denied" >&2
        return 1
      fi
      if [[ ! -f "$cron_file" ]]; then
        echo "no crontab for opc" >&2
        return 1
      fi
      cat "$cron_file"
      ;;
    -)
      cron_input=$(cat)
      printf '%s\n' "$cron_input" > "$cron_file"
      ;;
    *) return 2 ;;
  esac
}
"""
        cron_script = mock + template[start:end] + '\nprintf "%s\\n" "bootstrap continued"\n'
        entry = "*/5 * * * * /home/opc/health_check.sh"
        existing = "0 2 * * * /home/opc/existing.sh"
        scenarios = (
            ("first boot", "", None, [entry]),
            ("existing cron", "", existing, [existing, entry]),
            ("listed task", "", f"{existing}\n{entry}", [existing, entry]),
            ("read error", "denied", existing, [existing]),
        )
        with tempfile.TemporaryDirectory() as tmp:
            for i, (label, mode, initial, expected) in enumerate(scenarios):
                with self.subTest(label=label):
                    cron_file = Path(tmp) / f"cron-{i}"
                    if initial is not None:
                        cron_file.write_text(initial + "\n", encoding="utf-8")
                    result = subprocess.run(
                        [bash, "-s", "--", cron_file.as_posix(), mode],
                        input=cron_script, capture_output=True, text=True, timeout=10,
                    )
                    self.assertEqual(result.returncode, 1 if mode else 0, result.stderr)
                    self.assertEqual("bootstrap continued" in result.stdout, not mode)
                    self.assertEqual(cron_file.read_text(encoding="utf-8").splitlines(), expected)

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
