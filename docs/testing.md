# Pruebas y validación

Ejecuta los comandos desde la raíz del repositorio. Estas comprobaciones cubren el contrato y la configuración de Terraform. La comprobación de un entorno desplegado se hace por separado.

## Contrato de Deploy Studio

Con Python 3, ejecuta:

```text
python -m unittest discover -s tests -p "test_deploy_studio_contract.py" -v
```

En Windows también puedes usar `py -3`. La suite comprueba el manifiesto, sus salidas, el bucket privado, la exclusión de app/.env y la presencia de app/.env.example y el checkout del SHA seleccionado. Una ejecución correcta termina con `OK`. La prueba del arranque que necesita Terraform y Bash informa un salto si falta alguna de esas herramientas. [Pruebas del contrato](../tests/test_deploy_studio_contract.py)

## Validación de Terraform

Usa Terraform 1.9.8 para reproducir CI. En una copia de pruebas limpia, crea los archivos sintéticos de la fase **Prepare synthetic credential placeholders** y ejecuta los mismos comandos de CI:

```bash
mkdir -p terraform/.oci
cp terraform/config.example terraform/.oci/config
printf '%s\n' 'synthetic-ci-placeholder' > terraform/.oci/key.pem
terraform fmt -check -recursive terraform
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
```

`init` puede descargar los proveedores. El formateo pasa con código de salida 0 y `validate` confirma que la configuración es válida. Usa los archivos sintéticos únicamente en una copia de pruebas. [Flujo de CI](../.github/workflows/terraform.yml) · [Contrato de Terraform](../terraform/README.md)

## Si ya existe un despliegue

En Deploy Studio, comprueba que el trabajo haya terminado y abre **Application URL**. La VM pasa la comprobación de salud cuando Streamlit responde por HTTPS al terminar la inicialización. Inicia sesión y comprueba que el menú de módulos esté disponible. Si la aplicación no responde, consulta los registros de cloud-init en la VM y del trabajo en OCI Resource Manager.
