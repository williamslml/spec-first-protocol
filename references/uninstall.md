# Modo Retiro: desinstalar lo que añadió el setup

Objetivo: quitar **solo** lo que instaló el setup (el instalador `spec-first-protocol`), sin tocar lo que el usuario hizo después. Mismas reglas inviolables que al instalar: solo lectura hasta la aprobación, mínima intrusión, decide una persona, reversible.

## 1. Qué permite un retiro seguro (se prepara al instalar)

- **Manifiesto** (`templates.md` sección 1): registro: una acción por cambio, con `id`, `type`, `path` y, en `move`, `from`.
- **Marcadores con id** (`templates.md` sección 2): `<!-- sfp:start v1 id=N -->` … `<!-- sfp:end id=N -->`, donde N es el `id` de la acción `merge`. Permiten quitar un bloque sin tocar el resto del archivo.
- **Huellas** (`actions[].sha256`, cambian si cambia el contenido): al terminar la Fase 6, `scripts/fingerprint.sh --propose` mide cada archivo creado y bloque fusionado y deja una propuesta de manifiesto; si el usuario la aprueba, `--accept` la aplica (nadie copia huellas a mano).
- **Cambios en JSON** (`configure` con `format: json`): `changes` registra cada clave añadida, cambiada o quitada y cada elemento añadido a una lista, con su valor previo. Se deshace clave por clave sin tocar lo que el usuario cambió después. En el retiro, huella igual = el usuario no lo tocó = se puede quitar solo; huella distinta = lo editó = decide él.
- Instalaciones anteriores a 1.3.0: sin huellas ni ids. El retiro funciona, pero lo no comprobable queda `[MANUAL]`. El modo Actualización propone añadirlas (CHANGELOG 1.3.0).

## 2. Procedimiento con el usuario

1. **Confirmar alcance.** ¿Retiro total o solo una parte (p. ej. la orquestación de agentes, `orchestration.md` "Con → Sin")? En un retiro parcial se trabaja con las acciones acordadas y se dice qué queda.
2. **Simulación, siempre primero.** `sh scripts/uninstall.sh <proyecto>` (Windows: `scripts\run.ps1 uninstall <proyecto>`). No escribe nada. Mostrar el plan tal cual, agrupado:
   - `[AUTO]`: se quitará sin preguntar ítem por ítem (no cambió desde el setup).
   - `[MANUAL]`: necesita una decisión del usuario (sección 3).
   - `[INFO]`: ya no estaba; nada que hacer.
   - `[ERROR]`: algo no cuadra (ruta fuera del proyecto, marcadores sin pareja): resolverlo antes de seguir.
3. **Punto de retorno.** Con git: proponer commit (versión guardada) o tag `pre-sfp-uninstall` (con permiso; nunca commit sin él). Sin git: copiar los archivos con bloques fusionados y los `[AUTO]`.
4. **Aprobación explícita** de todo el plan `[AUTO]`, o ítem por ítem si el usuario prefiere.
5. **Aplicar** con `--apply`: el script ejecuta solo los `[AUTO]`, en este orden:
   1. archivos y bloques, por `id` de mayor a menor (lo último instalado sale primero);
   2. carpetas creadas, de la más profunda a la menos, **solo si quedan vacías** (un `.gitkeep` no cuenta);
   3. el manifiesto (`.sfp/`), al final y **solo si no queda nada pendiente**: mientras haya `[MANUAL]` se conserva, porque registra lo que falta.
6. **Resolver los `[MANUAL]`** uno a uno con el usuario (sección 3). Lo que decida quitar lo quita la IA con el comando que imprimió el script, mostrado antes.
7. **Repetir** la simulación, sin riesgo. Termina cuando sale con código 0 (nada pendiente) o cuando el usuario conserva lo que queda.
8. **Verificar e informar**: `git status`/diff contra el punto de retorno (solo debe faltar lo retirado); el proyecto compila y pasa pruebas si las tenía (comandos autorizados); informe breve: qué se quitó, qué se conservó y por qué, cómo deshacer el retiro.

## 3. Qué hacer con cada `[MANUAL]`

| Situación | Qué se le ofrece al usuario |
|---|---|
| Archivo creado por el setup y **editado después** | Conservarlo (pasa a ser suyo; se dice en el informe) · o borrarlo tras ver su contenido actual. Nunca borrarlo sin mostrarlo |
| Bloque fusionado **editado después** | Mostrar el bloque. Conservarlo tal cual (quitando solo los marcadores, si quiere) · o quitarlo entero · o dejar sus líneas y quitar las del setup |
| Ítem **sin huella** (instalación antigua) | Mostrar el contenido y, con git, `git log`/`git diff <backup.ref> -- <ruta>` para ver si cambió; decidir como en las filas anteriores |
| Carpeta creada con **archivos del usuario dentro** | Se conserva. Solo se ofrece moverlos si el usuario quiere quitar la carpeta |
| `move` (reestructuración) | Nunca automático: deshacerlo rompe importaciones y configuración actualizadas con él. Opciones: revertir los commits de la reestructuración (`git revert`), volver al respaldo, o `git mv` inverso + ajustar referencias como un plan nuevo (`scenarios.md` sección 3, por lotes) |
| Clave de un JSON (`configure` json) que el usuario **cambió después** | Mostrar el valor actual y el previo al setup; restaurar solo si el usuario lo pide. Las claves que siguen como las dejó el setup se revierten solas |
| Hook `commit-msg` de atribución (`templates.md` sección 17; script automático de git) | Es un bloque `merge` con marcadores o un `create` con huella: se retira como cualquier otro. Si quedó en `.git/hooks/`, no está versionado: solo afecta a esta copia local. Si se activó con `git config core.hooksPath .githooks`, esa configuración local se deshace con `git config --unset core.hooksPath` (o se restaura el valor previo anotado en `note`) en cada copia, y se quita del README el paso de activación. Lo global (`init.templateDir`) es `[MANUAL]` |
| `configure` sin marcadores ni `format: json` (permisos de la herramienta de IA en otros formatos, ajustes) | Mostrar la configuración actual y la anterior (del respaldo); el cambio de permisos lleva confirmación aparte (regla inviolable 7) |
| Herramienta externa instalada (dependencia, hook, plugin) | Desinstalarla con su método documentado vigente; no inventar comandos (regla inviolable 8) |
| Integración instalada por `integrations.sh` (registro en `.sfp/integrations.json`, o `.sfp/integrations-codex.json` para Codex) | **Antes** de `uninstall.sh`: `bash scripts/integrations.sh --uninstall` (plan) y, aprobado, `--uninstall --apply`, una vez por cada estado (con `--agent codex` para el de Codex). Retira lo del proyecto solo si no cambió; lo global queda `[MANUAL]` con su comando exacto (p. ej. `rtk init -g --uninstall`, `winget uninstall --id rtk-ai.rtk -e`), cada uno con confirmación aparte. Si RTK sigue activo, los comandos de evidencia del retiro van con `RTK_DISABLED=1` |

## 4. Casos especiales

- **Sin manifiesto** (modo sin rastros, o manifiesto entregado fuera del repo): pedir al usuario el manifiesto externo; si no lo hay, usar `discover.sh` (sección `setup-previo`, archivos con marcadores) y armar el plan a mano, todo como `[MANUAL]`.
- **Sin jq ni Python 3**: el script sale con 3; leer el manifiesto a mano y seguir el orden del paso 5 de la sección 2.
- **Producto en varios repos** (`scenarios.md` sección 5): un retiro por repo; el de coordinación al final, porque guarda los ADRs (decisiones de arquitectura) comunes que citan los otros.
- **Retiro tras cambiar de variante**: "Con → Sin orquestador" es un retiro parcial (solo la configuración del orquestador) más instalar las prácticas de la sección A; conservar specs y lecciones.
