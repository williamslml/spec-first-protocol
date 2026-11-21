# Adaptadores de runtime (genérico)

Ningún runtime (la herramienta de IA del agente) lee solo la carpeta de metodología global, que es la **fuente de verdad** e independiente de todos. Cada runtime elegido necesita una **capa de enlace** que lleve ese contenido adonde busca su configuración. Esa capa es propia de cada runtime y regenerable; no es metodología.

## Principio
1. **Una sola fuente de verdad** para las instrucciones del proyecto.
2. Cada runtime recibe un **punto de entrada breve** que remite a esa fuente, sin duplicarla.
3. Formas de enlace, de menos a más frágil: referencia por ruta dentro del archivo de instrucciones → copia generada (con cabecera "generado, no editar") → enlace simbólico (puede fallar en Windows o en ciertos sistemas de archivos).
4. Si el runtime no admite algo (agentes, skills, permisos finos), se pasa a texto en las instrucciones y se avisa.

## No asumir nombres ni rutas
Las convenciones cambian entre versiones. Procedimiento:
1. Preguntar al usuario qué runtimes usa.
2. Detectar la configuración que ya existe (Fase 1).
3. Comprobar la convención **vigente** en la documentación oficial (web o local). Si no se puede, preguntar al usuario o declarar la suposición como no verificada y marcarla en el plan.
4. Runtimes desconocidos o nuevos: procedimiento genérico de abajo.

Ejemplos *orientativos, no verificados* de dónde suelen estar las instrucciones: un archivo markdown en la raíz con nombre propio del runtime, o una carpeta oculta de reglas en la raíz o en la del usuario. Confirmar siempre antes de escribir.

## Procedimiento genérico para cualquier runtime
1. Identificar: (a) archivo o carpeta de instrucciones del proyecto, (b) mecanismo de agentes o roles, (c) skills o comandos, (d) permisos o restricciones de herramientas, (e) herramientas externas o MCP (protocolo para conectarlas).
2. Asociar cada elemento a su equivalente:

| Metodología | Equivalente en el runtime |
|---|---|
| Instrucciones del proyecto | Archivo o regla de proyecto |
| Plantillas `agents/*.md` | Sub-agentes, perfiles, modos o prompts del runtime |
| Skills | Skills, comandos o plugins, o texto en las instrucciones |
| Mínimo privilegio | Configuración de permisos del runtime |
| Tiers (niveles) de modelo | Selector de modelo del runtime o convención escrita |
| Capa de specs (especificaciones) | Comandos o instrucciones que lancen el flujo de specs |

3. Redactar el punto de entrada: qué metodología aplica, dónde están specs, ADRs (decisiones de arquitectura) y lecciones, reglas de aprobación humana, comandos de verificación del proyecto y qué agentes o roles existen.
4. Si el archivo ya existe, fusionar con marcadores.
5. Registrar en el manifiesto (registro de lo instalado) el runtime y la ruta.
6. Verificar (Fase 7) que el runtime carga el archivo, a su manera (p. ej. pidiéndole que resuma las instrucciones del proyecto).

## Varios runtimes en el mismo proyecto
- Elegir un **archivo canónico**: el del runtime principal o uno neutral.
- Los demás puntos de entrada solo llevan una referencia al canónico o una copia generada.
- Documentar cómo regenerar las copias y avisar en cada una que no se edite a mano.
- Mantener la coherencia: si dos runtimes reciben reglas contradictorias, parar y resolverlo.

## Contenido mínimo del punto de entrada (plantilla en `templates.md`)
- Variante de metodología (con o sin orquestador, que coordina agentes) y ruta de la carpeta global (si existe).
- Flujo de trabajo resumido (cambio trivial o no trivial).
- Ubicación real de specs, ADRs, runbooks (guías operativas) y lecciones en este proyecto.
- Comandos de verificación reales (test, lint, tipos).
- Acciones que requieren aprobación humana.
- Roles o agentes disponibles y cuándo usarlos.
- Tiers de modelo → modelos del usuario.
- Reglas de contexto mínimo: qué leer solo cuando haga falta.

## Permisos y seguridad
- Mostrar el contenido exacto de cualquier cambio de permisos y pedir confirmación aparte.
- No ampliar permisos para "facilitar" el setup (la instalación). Si necesita un permiso que el runtime no tiene, pedirlo al usuario.
- Sin orquestador: configurar lo mínimo necesario en **cada** runtime antes de usarlo.
