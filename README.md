<p align="center">
  <img src="docs/assets/oracle-ai-accelerator-cover.png" alt="Ícono de Oracle AI Accelerator con un globo de conversación blanco sobre fondo rojo" width="176">
</p>

<h3 align="center">Oracle AI Accelerator</h3>

<p align="center">Laboratorio desplegable en OCI para extraer texto de documentos, transcribir audio y consultar datos desde Streamlit.</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/Licencia-MIT-165D63?style=flat-square" alt="Licencia MIT"></a>
  <a href="https://github.com/jgangini/oracle-ai-accelerator/releases"><img src="https://img.shields.io/github/v/release/jgangini/oracle-ai-accelerator?style=flat-square" alt="Última versión publicada"></a>
  <a href="https://github.com/jgangini/oracle-ai-accelerator/actions/workflows/terraform.yml"><img src="https://github.com/jgangini/oracle-ai-accelerator/actions/workflows/terraform.yml/badge.svg" alt="Validación de Terraform"></a>
</p>

<p align="center">
  <a href="docs/architecture.md"><img src="https://img.shields.io/badge/Oracle-Cloud_Infrastructure-C74634?style=flat-square" alt="Oracle Cloud Infrastructure"></a>
  <a href="docs/tutorial.md"><img src="https://img.shields.io/badge/Interfaz-Streamlit-CC3340?style=flat-square" alt="Streamlit"></a>
  <a href="terraform/README.md"><img src="https://img.shields.io/badge/Infraestructura-Terraform-623CE4?style=flat-square" alt="Terraform"></a>
</p>

<p align="center">
  <a href="#inicio-rápido">Inicio rápido</a> ·
  <a href="docs/deployment.md">Despliegue</a> ·
  <a href="docs/architecture.md">Arquitectura</a> ·
  <a href="docs/tutorial.md">Tutorial</a> ·
  <a href="docs/testing.md">Pruebas</a>
</p>

## Inicio rápido

Necesitas acceso a [Deploy Studio](https://cloudtechnext.net/#deploy), un perfil OCI con clave de API y permisos en el compartimento de prueba. La región del perfil debe ofrecer OCI Generative AI.

1. Selecciona **Oracle AI Accelerator** y un [release publicado](https://github.com/jgangini/oracle-ai-accelerator/releases).
2. Carga **OCI config** y **API private key**. Selecciona el compartimento y completa las tres contraseñas del formulario.
3. Pulsa **Validate** y luego **Deploy**. Espera a que el trabajo quede en **Succeeded**.
4. Abre **Application URL** e inicia sesión como `admin` con la contraseña **Application password**. Para comprobar el flujo de documentos, sigue el [tutorial con el PDF de ejemplo](docs/tutorial.md).

La [guía de despliegue](docs/deployment.md) detalla las credenciales, los recursos que se crean y dónde revisar una ejecución detenida.

## Qué puedes probar

| Entrada | Resultado en el laboratorio |
| --- | --- |
| PDF e imágenes de documentos | Texto extraído, PDF con texto buscable y resultados del análisis. |
| Audio y voz | Transcripciones mediante OCI Speech. |
| CSV y texto | Consultas con Select AI y respuestas basadas en texto recuperado por similitud. |

![Flujos de extracción, indexación y respuesta para CSV, texto, PDF, imágenes, audio y voz en tiempo real](img/architecture.png)

Lee el diagrama por filas. Cada fila muestra qué servicio recibe un tipo de entrada, cómo se procesa y qué resultado llega a Streamlit. La [arquitectura de despliegue](docs/architecture.md) describe por separado la VM, Autonomous AI Database y el bucket privado.

## Documentación

- [Desplegar y verificar el acceso](docs/deployment.md).
- [Arquitectura y modelo de datos](docs/architecture.md).
- [Extraer texto del primer PDF](docs/tutorial.md).
- [Ejecutar las pruebas de contrato y Terraform](docs/testing.md).
- [Contrato y configuración de Terraform](terraform/README.md).
- [Demos](https://youtube.com/playlist?list=PLMUWTQHw13gbqqVHaCid3gUBIlvfVKaBu) · [Reportar un problema](https://github.com/jgangini/oracle-ai-accelerator/issues).

## Autoría y licencia

Proyecto de Joel Gangini Garcia. [Licencia MIT](LICENSE).
