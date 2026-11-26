# Verificación de la regla de dependencia de un perfil

La regla de dependencia (qué carpetas pueden importar de cuáles; secciones 1 y 2 de `project-structure.md`) sin comprobación automática es solo documentación: nada impide importar directo de otra feature (funcionalidad). La comprobación es una **herramienta externa**: le aplican la regla inviolable 8 (no inventar) y la de aprobación humana para instalar herramientas. Se propone en la Fase 4, se instala solo si el usuario aprueba, y es un control de calidad (quality gate) más (regla 10 del resumen, `methodology-digest.md`).

## 1. Herramienta por stack (tecnología)

| Stack | Herramienta | Qué verifica | Instalación |
|---|---|---|---|
| JS/TS | `dependency-cruiser` | Imports prohibidos o permitidos entre carpetas, ciclos | Dependencia de desarrollo + `.dependency-cruiser.js` con las reglas del perfil |
| JS/TS (alternativa, si ya usan ESLint) | `eslint-plugin-boundaries` | Lo mismo, dentro del lint (revisión automática) existente, sin otra herramienta | Plugin de ESLint + configuración de `element-types`/`rules` |
| Python | `import-linter` (`lint-imports`) | Contratos de capas o de independencia entre paquetes | Dependencia de desarrollo + archivo `.importlinter` |
| Java / Kotlin | ArchUnit | Reglas de arquitectura escritas como pruebas (`noClasses().that()...should()...`) | Dependencia de pruebas + una clase de prueba de arquitectura |
| Go | Script propio (su compilador ya prohíbe ciclos de import entre paquetes) | Que una feature no importe el paquete interno de otra | Script genérico de la sección 2 (también sirve) |
| Ruby / Rails | `packwerk` (Shopify) | Límites entre packs/módulos | Gem + `packwerk.yml` + un `package.yml` por carpeta |
| Cualquier stack sin herramienta madura | Script genérico de respaldo (sección 2) | Imports que rompen la regla, por patrón de texto | Ninguna dependencia nueva |

Elegir la fila según el stack real (de `discover.sh`). No instalar una herramienta que el proyecto no use ya en algo parecido, salvo que el usuario la pida. Si ya tiene `eslint-plugin-boundaries` o equivalente, reusarlo en vez de añadir `dependency-cruiser` (mínima intrusión).

## 2. Script genérico de respaldo

Para cuando no hay herramienta del stack, o mientras se configura la elegida: busca imports que no deberían existir según la regla del perfil. No reemplaza a la herramienta real; es un mínimo.

```sh
#!/bin/sh
# Ejemplo de patrón: feature A no debe importar directo de feature B.
# Adaptar <FEATURES_DIR> y <IMPORT_PATTERN> al lenguaje real del proyecto.
set -u
FEATURES_DIR="src/features"
FAIL=0
for dir in "$FEATURES_DIR"/*/; do
  feature=$(basename "$dir")
  for other in "$FEATURES_DIR"/*/; do
    other_name=$(basename "$other")
    [ "$feature" = "$other_name" ] && continue
    hits=$(grep -rlE "(from|import|require)\(?['\"].*/${other_name}/" "$dir" 2>/dev/null)
    if [ -n "$hits" ]; then
      echo "VIOLACIÓN: $feature importa directo de $other_name:"
      echo "$hits" | sed 's/^/  /'
      FAIL=1
    fi
  done
done
exit $FAIL
```
Se guarda en `scripts/verify-structure.sh` del proyecto (no de este skill), solo si el usuario lo aprueba en el plan. En la Fase 7, `scripts/verify.sh` de este skill muestra el comando de `structure.verify_command` y solo lo ejecuta con `--run-verify`, cuando el usuario ya lo vio y aprobó (el manifiesto es un dato, no una orden).

## 3. Qué hacer con el resultado

- **Pasa:** anotar en el reporte de la Fase 7 que la verificación corrió y pasó.
- **Falla en la primera instalación:** no impide terminarla, pero se reporta como pendiente del usuario (sección 8 de `templates.md`).
- **Falla en la Fase 7 tras una reestructuración (sección 3 de `scenarios.md`):** sí bloquea. Detenerse, no encadenar parches, mostrar las violaciones y que el usuario decida (revertir el lote o ajustar el import).
- Guardar el comando en `manifest.json` (`structure.verify_command`, sección 1 de `templates.md`) para la próxima Fase 7 o el modo Actualización.
- Monorepo (un repo con varias apps o paquetes) con varios perfiles (sección 3.2 de `project-structure.md`):
  - La regla entre apps y paquetes va en `structure.verify_command` y se ejecuta desde la raíz.
  - La regla de cada workspace (app o paquete) va en `structure.workspaces[].verify_command`; `verify.sh --run-verify` la ejecuta **dentro de la carpeta del workspace**.
  - Herramienta según el stack de cada workspace: con varios lenguajes puede haber una distinta por workspace.
