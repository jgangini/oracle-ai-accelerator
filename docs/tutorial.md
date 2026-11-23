# Extraer texto del primer PDF

Usa **AI Document Understanding** para abrir un PDF en Oracle AI Accelerator y comprobar el texto que se extrajo de sus páginas.

## Qué necesitas

- Un [laboratorio desplegado](deployment.md#comprobar-el-acceso) y un usuario con acceso al módulo **3: AI Document Understanding**.
- El archivo [`oci_data_science.pdf`](../app/data/knowledge_examples/3_module/oci_data_science.pdf) incluido en el repositorio, o cualquier PDF de prueba autorizado. Descárgalo antes de abrir el formulario.

## Procesar el documento

1. En la pantalla principal, pulsa **Create**.
2. En **Which module would you like to start with?**, elige **3: AI Document Understanding**.
3. Selecciona el idioma del PDF. Pulsa **Choose a File** y adjunta el documento.
4. Escribe una descripción fácil de reconocer en **File Description**. Elige **PDF** como salida y pulsa **Save**.
5. Cuando se muestre el documento en la lista, marca **Select** en su fila y abre el icono **View**.

## Verificar el resultado

| Campo | Qué debes ver |
| --- | --- |
| **Pages** | La cantidad de páginas del PDF que cargaste. |
| **Output** | El nombre del PDF de salida con el sufijo `_trg.pdf`. |
| **Text** | Texto del documento extraído de sus páginas. |

Object Storage conserva el original, el PDF buscable y el JSON del análisis. [Flujo de documentos](architecture.md#flujo-de-documentos)

Si el módulo falta, revisa los permisos del usuario. Si el módulo aparece y **Save** falla, comprueba los permisos de Document Understanding y Object Storage y la región del despliegue. [Revisión de una ejecución](deployment.md#revisar-una-ejecución-detenida)
