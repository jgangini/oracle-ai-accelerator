# Preparar servicios y permisos de OCI

Para el flujo automatizado, prepara una identidad OCI y un compartimento de laboratorio. Deploy Studio delega en Resource Manager la creación de Compute, red, Object Storage y Autonomous AI Database. Para ejecutar la aplicación en Windows, el administrador prepara esos servicios en OCI antes de configurar el entorno local. [Guía de despliegue automatizado](4-automated-deployment-on-oci-resource-manager-linux.md) · [Guía de Windows](3-instance-or-local-machine-configuration-windows.md)

| Recurso | Qué preparar |
| --- | --- |
| Región | Usa en el perfil OCI la región del laboratorio. Comprueba disponibilidad y límites de Compute, Autonomous AI Database y los modelos de Generative AI que usarás. |
| Compartimento e IAM | Usa un compartimento dedicado y un grupo autorizado. Reserva la creación de compartimentos a quienes administran ese alcance. |
| Resource Manager | Autoriza la creación del stack y de sus trabajos, así como las operaciones sobre los recursos que indica el plan en el compartimento de destino. |
| Autonomous AI Database | El flujo automatizado usa 26ai con carga OLTP y Developer Tier. Para el flujo manual, prepara una base de laboratorio y descarga su wallet. |
| Object Storage | Usa un bucket privado. Limita el acceso a los objetos que necesitan la aplicación y el proceso de instalación. |
| Servicios de IA | Concede al grupo las operaciones de Document Understanding, Speech y Generative AI que correspondan a los módulos que quieras utilizar. |

Crea las políticas para grupos identificados y con alcance al compartimento. Para dimensionar los permisos, toma como referencia las operaciones del plan y los módulos activos. [Políticas IAM de OCI](https://docs.oracle.com/en-us/iaas/Content/Security/Reference/iam_security_topic-IAM_Security_Policies.htm) · [Protección de Object Storage](https://docs.oracle.com/en-us/iaas/Content/Security/Reference/objectstorage_security.htm)

Si usas una VM Windows, limita el acceso remoto al origen autorizado de los operadores mediante las reglas de la red. Para una ejecución en tu equipo, abre Streamlit en localhost.
