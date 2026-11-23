# Ejecutar Oracle AI Accelerator en Windows

Esta ruta sirve para ejecutar Streamlit desde una máquina Windows con servicios OCI ya preparados. El flujo automatizado configura su propia VM Linux. [Preparar servicios OCI](2-creating-and-preparing-services-for-the-project.md) · [Despliegue automatizado](4-automated-deployment-on-oci-resource-manager-linux.md)

## Preparar el entorno

Necesitas Git, Python 3.11, un perfil OCI con clave de API, una base Autonomous AI Database de laboratorio y su wallet. Desde PowerShell, clona el repositorio y selecciona el release que quieras usar. El ejemplo usa `v1.0.5`.

```powershell
git clone https://github.com/jgangini/oracle-ai-accelerator.git
Set-Location oracle-ai-accelerator
git switch --detach v1.0.5
py -3.11 -m venv .venv
Copy-Item app/.env.example app/.env
```

1. Configura el perfil en `$HOME/.oci/config` y apunta `key_file` a la clave de API local. El perfil predeterminado es `DEFAULT`. Para otro perfil, ajusta `CON_OCI_PROFILE_NAME` en `app/.env`.
2. Extrae el wallet de la base en `app/wallet/`. En `app/.env`, configura las credenciales de la base de laboratorio, la contraseña del wallet y los alias del archivo `tnsnames.ora`. Usa `./wallet` en `CON_ADB_WALLET_LOCATION` al ejecutar la aplicación desde `app/`.
3. Completa el compartimento, el namespace, el bucket y los endpoints de IA y voz de la región del perfil. Conserva los valores reales en tu entorno local.

## Instalar y abrir

Ejecuta la instalación en una base de laboratorio vacía. El script crea el usuario de base de datos y el esquema. Conserva la salida de instalación en privado porque el script manual puede mostrar sentencias SQL con datos de configuración.

```powershell
Set-Location setup
..\.venv\Scripts\python.exe setup.py
Set-Location ../app
..\.venv\Scripts\python.exe -m streamlit run app.py --server.address 127.0.0.1 --server.port 8501
```

Abre `http://127.0.0.1:8501` y verifica que aparece la pantalla de inicio de sesión. Inicia sesión como `admin` con la contraseña inicial definida en el SQL y cámbiala en **Profile** antes de permitir acceso a otras personas. [SQL de usuarios](../setup/autonomous_database/developer/c.TABLE_USERS.sql)
