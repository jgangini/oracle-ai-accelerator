# Desplegar Oracle AI Accelerator con OCI Resource Manager

Deploy Studio empaqueta el Terraform del release elegido y coordina los trabajos de OCI Resource Manager. El despliegue aprovisiona una VM Linux con Streamlit, una base Autonomous AI Database 26ai y un bucket privado. La VM instala el código del mismo commit que usa Terraform.

## Requisitos

- Acceso a Deploy Studio y una versión publicada que incluya el [manifiesto v2](../terraform/deploy-studio.json).
- Perfil OCI con clave de API y acceso a la región y al compartimento del laboratorio. [Preparar servicios y permisos](2-creating-and-preparing-services-for-the-project.md)

La VM recibe una IP pública y las reglas de red predeterminadas permiten conexiones a los puertos configurados desde cualquier IPv4. Revisa el acceso de red antes de desplegar y usa datos de laboratorio.

## Ejecutar el despliegue

1. En Deploy Studio, elige **Oracle AI Accelerator** y un release. Carga **OCI config** y **API private key**.
2. Confirma la región que figura en el perfil OCI. En **Compartment mode**, crea un compartimento si tienes permiso o elige uno existente.
3. Completa **Database ADMIN password**, **Database wallet password** y **Application password**. Puedes usar el generador del formulario. Las contraseñas admiten de 12 a 30 caracteres y requieren una mayúscula, una minúscula y un número. Evita las comillas y la palabra `admin`.
4. Pulsa **Validate** para comprobar el acceso y los datos. **Deploy** autoriza la ejecución del plan y el inicio automático de APPLY si el plan pasa. Para aprobar un plan por separado, usa trabajos independientes de Resource Manager.
5. Una vez completado el despliegue, abre **Application URL**. Inicia sesión como `admin` con el valor de **Application password** y comprueba que se abre el menú de módulos.

La URL inicial usa un certificado autofirmado. Para compartir la aplicación fuera del laboratorio, configura un certificado de confianza y limita el acceso a la red autorizada.

## Consultar el resultado

- Si falla el plan, consulta su primera operación fallida en Resource Manager y comprueba permisos, región y cuota.
- Si la VM se crea y falla después, consulta el estado de cloud-init y los registros locales de Streamlit o Nginx. El trabajo de Terraform espera a que la aplicación responda a su comprobación de salud.
- El despliegue entrega la URL y puede entregar artefactos privados, como el wallet y la clave SSH de la VM. Trata también el estado de Terraform y los registros como sensibles. [Credenciales, variables y validación](../terraform/README.md)
