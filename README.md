<p align="center">
  <img src="img/vm-login.png" alt="Pantalla de inicio de sesión de Oracle AI Accelerator" width="720">
</p>

# Oracle AI Accelerator

Oracle AI Accelerator es una aplicación de laboratorio para equipos que quieren probar cómo procesar documentos, imágenes, audio y texto con Oracle Cloud Infrastructure (OCI). Desde Streamlit se pueden transcribir conversaciones, extraer texto de documentos y consultar información con agentes y búsqueda semántica.

## Inicio rápido

Necesitas una cuenta de OCI, acceso a Deploy Studio y un perfil OCI con clave de API y permisos en el compartimento de prueba.

1. En Deploy Studio elige **Oracle AI Accelerator** y un release publicado compatible con el manifiesto v2.
2. Carga **OCI config** y **API private key**. La región se toma del perfil. Selecciona un compartimento nuevo o existente y completa las tres contraseñas del formulario.
3. Pulsa **Validate**. Cuando termine, selecciona **Deploy** para iniciar el plan y, si pasa, la creación automática de los recursos. Sigue el resultado en Deploy Studio.
4. Abre la URL HTTPS del despliegue e inicia sesión como `admin` con el valor que ingresaste en **Application password**.

[Guía de despliegue con Deploy Studio](docs/4-automated-deployment-on-oci-resource-manager-linux.md) · [Releases de GitHub](https://github.com/jgangini/oracle-ai-accelerator/releases)

## Arquitectura de los componentes

![Flujo de extracción, indexación y generación para CSV, texto, PDF, imágenes, audio y voz en tiempo real](img/architecture.png)

Lee la figura por filas para seguir cada tipo de entrada y de izquierda a derecha para ver cómo se procesa y llega a Streamlit.

1. **Extracción.** Select AI consulta datos tabulares y Select AI RAG recupera información de textos para responder. OCI Document Understanding extrae contenido de PDF, OCI Speech transcribe audio y voz en vivo, y los modelos multimodales de OCI Generative AI procesan imágenes.
2. **Indexación.** OCI Object Storage conserva archivos de entrada y resultados intermedios. Para los módulos con búsqueda semántica, Autonomous AI Database 26ai guarda los fragmentos indexados y sus vectores para recuperarlos por similitud.
3. **Generación.** Según el módulo, Generative AI y los agentes usan los resultados de la extracción o el contexto recuperado para responder. Streamlit presenta los módulos y sus resultados.

En el despliegue, Deploy Studio inicia el aprovisionamiento mediante OCI Resource Manager. La VM de Compute aloja Streamlit y obtiene el wallet de la base desde un bucket privado durante el arranque.

[Modelo de datos](docs/5-data-model-documentation.md) · [Archivos SQL del esquema](setup/autonomous_database) · [Aplicación Streamlit](app/app.py)

## Documentación

- [Arquitectura](docs/architecture.md) y recorrido desde el despliegue hasta el uso del laboratorio.
- [Pruebas y validación](docs/testing.md) del contrato y de Terraform.
- [Tutorial de Document Understanding](docs/tutorial.md) para procesar el primer PDF.
- [Activar una cuenta de Oracle Cloud](docs/1-create-and-activate-an-oracle-cloud-account.md)
- [Preparar servicios y permisos OCI](docs/2-creating-and-preparing-services-for-the-project.md)
- [Ejecutar la aplicación en Windows](docs/3-instance-or-local-machine-configuration-windows.md)
- [Contrato, infraestructura y validación de Terraform](terraform/README.md)
- [Reportar un problema](https://github.com/jgangini/oracle-ai-accelerator/issues) y [ver las demos](https://youtube.com/playlist?list=PLMUWTQHw13gbqqVHaCid3gUBIlvfVKaBu)

## Créditos y licencia

Joel Gangini Garcia es el autor del proyecto. OpenAI Codex asistió en la actualización de la documentación y del contrato de despliegue. El código se distribuye bajo la [licencia MIT](LICENSE).
