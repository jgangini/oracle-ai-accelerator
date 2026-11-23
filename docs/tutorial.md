# Procesar un primer documento

Este recorrido usa el módulo de documentos para extraer texto de un PDF y consultar el resultado en Oracle AI Accelerator.

## Preparar el laboratorio

- Para instalar el laboratorio, prepara un perfil OCI con clave de API y permisos en el compartimento de destino. [Flujo de despliegue](architecture.md#despliegue)
- Inicia sesión con un usuario que tenga acceso al módulo **3: AI Document Understanding**. Usa un PDF de prueba autorizado y sin datos sensibles.

## Cargar y procesar el PDF

1. En la pantalla principal, pulsa **Create**.
2. En **Which module would you like to start with?**, selecciona **3: AI Document Understanding**.
3. Elige el idioma del archivo. Pulsa **Choose a File** y selecciona el PDF.
4. Escribe una descripción en **File Description**, elige **PDF** como tipo de salida y pulsa **Save**.
5. Cuando termine el procesamiento, marca **Select** en la fila del documento y pulsa el icono **View**. Consulta **Pages**, el nombre del archivo en **Output** y el contenido extraído en **Text**.

El resultado esperado es un registro del documento, el número de páginas y el archivo de salida. Si el módulo no aparece, comprueba los permisos del usuario. Si aparece y el análisis falla, revisa los permisos de OCI, la región y el bucket de la instalación. [Arquitectura del flujo](architecture.md)
