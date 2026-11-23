# Terraform de Oracle AI Accelerator

Esta carpeta contiene el paquete que Deploy Studio entrega a OCI Resource Manager. El contrato es [deploy-studio.json](deploy-studio.json). La [guía de despliegue](../docs/architecture.md#despliegue) describe el recorrido desde el formulario hasta el inicio de sesión.

## Contrato del paquete

El manifiesto v2 describe los campos del formulario y su relación con las variables de Terraform. Deploy Studio aporta el compartimento, tenancy, región, namespace, sufijo de despliegue y `source_commit_sha`. El SHA se resuelve desde el release y fija la revisión que instala la VM. `source_ref` es una alternativa para ejecuciones manuales y queda fuera del formulario.

Las configuraciones de Autonomous AI Database, red y Compute están en [variables.tf](variables.tf). El bucket es privado. [Cálculo de nombres por despliegue](naming.tf) · [Script de arranque de la VM](templatefile/user_data.sh)

## Credenciales y artefactos

- Deploy Studio incorpora el config y la clave de API de OCI al paquete del trabajo. La VM usa esa clave para llamar a OCI y configurar Select AI en Autonomous Database. Usa una identidad de laboratorio con permisos ajustados al compartimento y restringe el acceso a la VM y al stack.
- La VM solicita su wallet directamente a Autonomous AI Database con la identidad OCI del despliegue. Esa identidad necesita permiso para generar el wallet de la base creada. Terraform genera por separado el wallet que Deploy Studio entrega como artefacto. El trabajo y su estado, los registros de instalación y los artefactos de acceso deben tratarse como sensibles.
- Mantén fuera de Git los archivos OCI reales, claves, wallets, variables privadas y estados de Terraform. Para ejecutar Terraform directamente hace falta preparar `.oci/config` y `.oci/key.pem` con acceso privado. Si aprovisionas la VM, el config incorporado debe apuntar a `/home/opc/.oci/key.pem`.

El correo de éxito presenta primero **Autonomous Database** con el usuario `ADMIN`, su contraseña y la del wallet. Luego presenta **Application VM** con la URL, el usuario `admin` y la contraseña de la aplicación. Adjunta el wallet, el paquete de acceso SSH, el registro de ejecución con secretos redactados y el código fuente de Terraform sin las credenciales OCI. La URL de la aplicación también está disponible en Deploy Studio.

## Validación automatizada

El [workflow de Terraform](../.github/workflows/terraform.yml) comprueba el contrato del formulario, el formato y la configuración de Terraform. Las pruebas de arranque usan un repositorio de ejemplo para verificar que la VM instala el commit seleccionado. También comprueban que la VM configura la tarea de salud cuando `opc` todavía no tiene crontab y conserva las tareas existentes. Las comprobaciones usan credenciales sintéticas.
