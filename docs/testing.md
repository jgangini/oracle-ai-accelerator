# Pruebas y validación

| Comprobación | Qué demuestra |
| --- | --- |
| Contrato de Deploy Studio | El manifiesto declara los campos, las salidas, los artefactos y el orden del correo esperado. |
| Terraform local y CI | El paquete tiene formato consistente y la configuración es válida con los proveedores instalados. |
| Runtime de Python | Streamlit puede serializar un DataFrame con las versiones instaladas de NumPy, pandas y PyArrow. |
| Prueba del laboratorio | Un despliegue real puede arrancar, aceptar un inicio de sesión y procesar el PDF de ejemplo. |

## Contrato de Deploy Studio

Desde la raíz del repositorio, con Python 3 disponible:

~~~bash
python -m unittest discover -s tests -p "test_deploy_studio_contract.py" -v
~~~

En Windows puedes usar `py -3` en lugar de `python`. La suite contiene 10 comprobaciones. Para probar el checkout del SHA durante el arranque necesitas Bash y Terraform. La prueba del crontab necesita Bash. Revisa cualquier `skipped` en la salida antes de dar por validado el arranque. [Pruebas del contrato](../tests/test_deploy_studio_contract.py)

## Terraform

Para reproducir el workflow usa **Terraform 1.9.8** y una copia de pruebas sin archivos OCI reales. Ejecuta con Bash:

~~~bash
mkdir -p terraform/.oci
cp terraform/config.example terraform/.oci/config
printf '%s\n' 'synthetic-ci-placeholder' > terraform/.oci/key.pem
terraform fmt -check -recursive terraform
terraform -chdir=terraform init -backend=false -input=false
terraform -chdir=terraform validate
~~~

`init` puede descargar proveedores. `fmt -check` debe terminar con código 0 y `validate` debe indicar que la configuración es válida. Los archivos sintéticos sirven para esta validación. [Workflow de GitHub Actions](../.github/workflows/terraform.yml)

## Runtime de Python

El instalador comprueba la serialización de datos de Streamlit antes de configurar la base de datos. El entorno de Python 3.11 usa PyArrow 26.0.1 con NumPy 2.0.2. NumPy 2.0 satisface el límite de TensorFlow 2.18 y las versiones de LangChain declaradas admiten NumPy 2. Para repetir la comprobación sin credenciales de OCI, instala las dependencias en un entorno virtual de Python 3.11 y ejecuta el mismo chequeo.

~~~bash
python -m pip install -r setup/requirements.txt
python -m pip check
python setup/check_runtime.py
~~~

## Prueba de un despliegue real

1. Confirma **Succeeded** en Deploy Studio y copia la URL del mismo job.
2. Abre la URL por HTTPS e inicia sesión en la aplicación con el usuario `admin`.
3. Procesa el [PDF de ejemplo](tutorial.md) y comprueba **Pages**, **Output** y **Text**.
4. Abre **Agents**, **Agent Builder**, **AI Speech Real-Time** y **Select AI** y verifica que carguen sin errores de PyArrow.
5. Si falla un paso, registra el release, el estado, la región y el mensaje relevante. Retira credenciales y contenido privado del reporte.

CI ejecuta las comprobaciones del contrato y de Terraform. El aprovisionamiento, la autenticación y el primer documento se verifican en el laboratorio. [Guía de despliegue](deployment.md)
