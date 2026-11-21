# Windows: cómo ejecutar los scripts del skill

Los scripts (`discover.sh`, `verify.sh`, `fingerprint.sh`, `uninstall.sh`, `sfp-section.sh`) son `sh` POSIX (el intérprete de comandos estándar de Unix). La excepción es `integrations.sh`: requiere **bash ≥ 4** (Git Bash lo trae; `run.ps1 integrations` usa `bash` también en WSL, donde `sh` suele ser dash).

A propósito, no hay versión en PowerShell: dos versiones divergirían y los errores corregidos en una reaparecerían en la otra. En su lugar, `scripts/run.ps1` busca un `sh` y le pasa el script con las rutas convertidas.

## Orden de preferencia

1. **Git for Windows (Git Bash).** Lo más común: si el usuario tiene git, ya tiene `sh.exe`.
   ```powershell
   powershell -ExecutionPolicy Bypass -File <skill>\scripts\run.ps1 discover C:\ruta\al\proyecto
   ```
   O desde una terminal Git Bash: `sh <skill>/scripts/discover.sh /c/ruta/al/proyecto`.
2. **WSL** (Linux dentro de Windows). `run.ps1` lo usa si no hay Git Bash, convirtiendo las rutas con `wslpath`. Desde una terminal WSL: `sh /mnt/c/<skill>/scripts/discover.sh /mnt/c/ruta/al/proyecto`. Atención: dentro de WSL, `git` ve el repositorio con los finales de línea y permisos de Linux. Si el proyecto se trabaja desde Windows, preferir Git Bash.
3. **Ninguno de los anteriores.** `run.ps1` sale con código 4 y lo explica. Hacer las comprobaciones a mano (lista de `scenarios.md`; para verificar, `structure-verification.md` y la lista de las secciones 1 a 4 al inicio de `verify.sh`) y **decir en el plan y en el reporte que no se usó el script**. No instalar nada para resolverlo sin aprobación (regla inviolable 7).

## Requisitos y diferencias conocidas

- **Lector de JSON** (para `verify.sh`, `fingerprint.sh`, `uninstall.sh`): `jq`, o Python 3 como `python3` **o** `python` (en Windows suele llamarse `python`). Sin ninguno, esos scripts terminan con código 3 ("incompleto"), nunca con "sin fallas". Validar el manifiesto contra su esquema, `fingerprint.sh --propose/--accept` y el retiro clave por clave de JSON necesitan Python 3 (con solo `jq` quedan incompletos o manuales).
- **Finales de línea**: en Windows, la salida de Python/jq trae `\r\n`; los scripts la normalizan. Si un archivo del proyecto tiene `\r\n`, las huellas sha256 (códigos que identifican el contenido exacto) se calculan sobre los bytes reales. No cambiar `core.autocrlf` entre la instalación y el retiro, o las huellas no coincidirán (el retiro lo trataría como "editado" y lo dejaría en `[MANUAL]`, el lado seguro).
- **Symlinks** (accesos directos a otro archivo o carpeta): en Windows pueden requerir el modo desarrollador o permisos de administrador; por eso `runtime-adapters.md` los deja como último recurso. `discover.sh` los cuenta igual.
- **Política de ejecución**: `-ExecutionPolicy Bypass` solo afecta a ese proceso; no cambia la configuración del sistema. Si la organización lo prohíbe, ejecutar directamente desde Git Bash.
- **Códigos de salida**: `run.ps1` devuelve el mismo código que el script (`$LASTEXITCODE`).
