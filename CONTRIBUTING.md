# Cómo contribuir

Gracias por querer colaborar con spec-first-protocol. Cualquier persona puede proponer cambios, y solo los dos mantenedores, [williamslml](https://github.com/williamslml) y [ncuzcoz-cloud](https://github.com/ncuzcoz-cloud), pueden aceptarlos.

El detalle completo está en la sección [Contribuciones](README.md#contribuciones) del README. Este es un resumen para empezar.

## Proponer un cambio en cinco pasos

1. Hacer un *fork* del repositorio, que es una copia propia, con el botón **Fork** de la página principal.
2. Clonar esa copia y crear una rama con un nombre descriptivo, con la forma `tipo/efecto-en-pocas-palabras`. Por ejemplo, `fix/error-al-instalar-en-windows`.
3. Hacer los cambios y ejecutar las comprobaciones:

   ```bash
   bash tests/ejecutar.sh
   python tests/verificar_formato.py
   ```

4. Subir la rama a la copia propia y abrir una solicitud de cambios hacia `master`, completando la plantilla que aparece.
5. Un mantenedor revisa la solicitud. Puede pedir ajustes y, con su aprobación, se mezcla.

## Reglas que valen para todas las personas

Incluidos los mantenedores:

- Mensajes de commit que explican qué cambió, por qué y cómo comprobarlo.
- Una entrada en el [CHANGELOG](CHANGELOG.md) con su apartado "Delta para proyectos ya instalados", si el cambio afecta a la skill.
- Textos en español neutro y en lenguaje claro, sin emojis.
- Sin firmas de asistentes de IA en los commits.

## Otras formas de ayudar

- **Reportar un problema o proponer una idea:** abrir un [issue](../../issues/new/choose). Si usas la skill con el CLI `gh` instalado y con sesión iniciada, la skill puede preparar el reporte por ti y publicarlo cuando lo apruebes.
- **Reportar una vulnerabilidad:** seguir lo que indica [SECURITY.md](SECURITY.md). No abrir un issue público.
