# Desplegar Oracle AI Accelerator

Deploy Studio aprovisiona el laboratorio en OCI a partir de un release de GitHub. Conserva el SHA de esa revisión y ejecuta el aprovisionamiento con OCI Resource Manager.

## Antes de empezar

- Accede a [Deploy Studio](https://cloudtechnext.net/#deploy) y elige una [versión publicada](https://github.com/jgangini/oracle-ai-accelerator/releases).
- Usa un perfil OCI con clave de API y permisos para aprovisionar en el compartimento elegido. Deploy Studio toma la región del perfil. El proyecto requiere una región con OCI Generative AI.
- El stack crea una red, una VM Linux de Compute, Autonomous AI Database y un bucket privado de Object Storage. Usa un compartimento de laboratorio.
- Guarda las tres contraseñas en un lugar privado. El formulario las solicita por separado porque cumplen funciones diferentes.

## Validar y desplegar

1. En **Deploy Studio**, selecciona **Oracle AI Accelerator** y el release.
2. Adjunta **OCI config** y **API private key**. Confirma que **OCI region** corresponda al perfil que quieres usar.
3. En **Compartment mode**, elige **New compartment** para crear uno o **Existing compartment** para seleccionar uno disponible.
4. Completa los campos de acceso.

   | Campo en el formulario | Se usa para |
   | --- | --- |
   | **Database ADMIN password** | Administrar Autonomous AI Database con el usuario `ADMIN`. |
   | **Database wallet password** | Abrir el wallet de conexión a la base. |
   | **Application password** | Iniciar sesión en Streamlit con el usuario `admin`. |

5. Pulsa **Validate**. Cuando los datos queden validados, pulsa **Deploy**. Resource Manager genera el plan y aplica ese plan si se completa correctamente.
6. Espera a **Succeeded**. Durante la inicialización, la VM instala la aplicación, obtiene el wallet de Autonomous AI Database y comprueba que Nginx responde por HTTPS.

## Comprobar el acceso

Abre **Application URL** en el panel de Deploy Studio. Inicia sesión con `admin` y **Application password**. El menú de módulos indica que el acceso web funciona. El [tutorial del PDF](tutorial.md) comprueba además la ruta de Object Storage y Document Understanding.

Si el envío está habilitado, Deploy Studio usa el correo de tu cuenta para entregar los accesos de Autonomous Database y Application VM y los archivos que declara el release. El usuario de SSH de la VM es `opc`. [Contenido del correo](../terraform/README.md#correo-de-acceso)

## Revisar una ejecución detenida

| Etapa | Qué comprobar |
| --- | --- |
| **Validate** | Región y permisos del perfil, par de archivos OCI y campos requeridos del formulario. |
| **Terraform plan** | Diagnóstico de PLAN en Resource Manager y permisos del compartimento. |
| **Terraform apply** | Recurso que falla en APPLY y mensaje original de OCI. |
| **Application setup** | En la VM, estado de cloud-init y `/var/log/cloud-init-output.log`. El arranque termina cuando pasa la comprobación de salud por HTTPS. |
| **Sign-in** | URL del job correcto, usuario `admin` y valor de **Application password**. |

La VM de laboratorio tiene IP pública y usa un certificado inicial autofirmado. La lista de seguridad del ejemplo admite tráfico de entrada desde cualquier origen en los puertos configurados. Restringe el acceso a redes autorizadas y configura un certificado de confianza antes de compartir el laboratorio.

[Arquitectura](architecture.md) · [Contrato de Terraform](../terraform/README.md) · [Pruebas](testing.md)
