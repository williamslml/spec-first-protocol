# Prácticas de desarrollo: cómo se ejecuta el trabajo una vez aprobado

Este documento reúne las reglas de trabajo diario que el skill lleva al proyecto, además de las reglas de la metodología del resumen (`methodology-digest.md`). Se aplican tanto al instalar SFP (Fase 6 de `SKILL.md`) como a cada cambio que se haga después en el proyecto. El punto de entrada de cada proyecto las resume en pocas líneas (sección 3 de `templates.md`); aquí está el detalle.

Ninguna de estas reglas da permiso para saltarse una aprobación: todo lo que exige aprobación humana (publicar, subir código, mezclar o borrar ramas, borrar archivos, instalar programas, tocar producción, cambiar permisos) la sigue exigiendo.

## 1. Ejecutar un plan aprobado de corrido

La aprobación de un plan cubre **todas** sus fases y tareas, no cada una por separado. Al terminar una fase sin problemas, se pasa a la siguiente sin preguntar "¿sigo?".

Antes de pasar a la fase siguiente, se revisa lo que se acaba de hacer (autoauditoría): que el resultado coincide con lo que el plan decía y que las verificaciones de esa fase pasan.

Hay cuatro situaciones distintas, y cada una tiene su respuesta:

| Situación | Qué se hace |
|---|---|
| La fase terminó y su revisión pasó | Se sigue con la siguiente fase del plan, sin preguntar |
| Un detalle menor que se puede corregir dentro de lo aprobado (formato, una errata, un ajuste que no cambia el alcance) | Se corrige, se sigue y se anota para el resumen final |
| Algo falla de verdad (un comando, una prueba, una verificación) | Se detiene, no se encadenan parches, se informa y se ofrece volver atrás en parte o del todo |
| Aparece algo que el plan no contemplaba (un supuesto falso, un conflicto real, un cambio de alcance) | Se detiene y se explica qué cambió; se sigue solo cuando la persona decide |

Si una tarea del plan incluye una acción que siempre requiere aprobación, se pide **esa** aprobación puntual justo antes de ejecutarla (no la del plan completo otra vez). Con la respuesta, se sigue con el resto del plan sin volver a preguntar por las fases siguientes.

Al terminar, se entrega un resumen: qué se hizo, qué se corrigió sobre la marcha y qué quedó pendiente.

## 2. Ejecutar los comandos, no pedírselos a la persona

Si un comando, un script o una verificación está dentro de lo que el asistente puede ejecutar, y ya está permitido o aprobado, lo ejecuta él y muestra el resultado. No se le pide a la persona que lo copie y lo ejecute.

Solo se le pasa a la persona lo que de verdad no puede hacer el asistente:
- Algo que necesita credenciales que el asistente no tiene (contraseñas, códigos de un solo uso, iniciar sesión).
- Algo en un sistema o una cuenta externa a la que el asistente no tiene acceso.
- Una decisión que no le corresponde al asistente.
- Algo que el entorno le impide (por ejemplo, el runtime no le da terminal o la persona negó el permiso). En ese caso se dice por qué y se da el comando exacto.

Las acciones que siempre requieren aprobación siguen pidiéndola antes de ejecutarse: esta regla no las convierte en automáticas.

## 3. Antes de concluir que algo no es viable: evidencia

Un "no se puede" sin pruebas suele ser una configuración por defecto, una versión antigua o un enfoque concreto, no una imposibilidad real. Y una vez escrito, condiciona decisiones futuras sin que nadie lo cuestione. Por eso, antes de registrar que algo no es viable (en una tarea, una spec, un ADR o el código):

1. **Preguntar por las restricciones externas** que acotan las alternativas: una librería o herramienta impuesta por el cliente, una política de seguridad, una versión obligatoria, un proveedor único. Si las hay, solo se buscan alternativas compatibles con ellas, y se anotan.
2. **Probar en el proyecto real**, no de memoria ni en teoría. Si no se puede probar en el entorno actual, se dice y se explica por qué.
3. **Explorar al menos dos o tres alternativas distintas** dentro de lo permitido. Por ejemplo: otra versión de la dependencia, otro parámetro o modo de uso, otro enfoque para el mismo resultado, o la documentación oficial vigente en lugar del conocimiento previo.
4. **Registrar la evidencia de cada intento**: qué se probó, cómo y qué resultado o error dio. "No funcionó" no basta.
5. **Decidir con la evidencia:**
   - Si alguna alternativa logra el mismo objetivo, la solución es viable: se adopta y se sigue, sin registrar ninguna inviabilidad.
   - Si una alternativa funciona pero no se puede usar por una restricción ajena a la técnica (una política, una licencia, un contrato), no es una inviabilidad técnica: se registra como **restricción organizativa o contractual**, con la alternativa que sí funcionaría y la razón por la que no se usa.
   - Solo si ninguna alternativa permitida logra el objetivo, se declara la inviabilidad, con la evidencia del paso 4.
6. **Si afecta a una decisión ya tomada en la spec**, se señala para revisarla. No se ajusta el código en silencio alrededor de la supuesta inviabilidad.

La revisión independiente (sección 8) no aprueba una tarea que declara algo inviable sin esta evidencia.

## 4. Respetar el orden del backlog

Cada ítem de la lista de tareas (o del backlog) se prueba y se evalúa solo cuando le toca y está aprobado, nunca antes:
- No se trabaja ni se adelanta código de un ítem que todavía no corresponde.
- No se declara viable ni inviable un ítem futuro.
- Si mientras se trabaja en un ítem surge una duda sobre uno posterior, se anota como nota o riesgo para revisarla cuando llegue su turno.

La revisión independiente rechaza la evidencia de inviabilidad que corresponda a un ítem fuera de su orden.

## 5. Dónde viven las pruebas

Dónde se guardan los tests es una **convención del proyecto**: se detecta o se pregunta, nunca se impone (regla inviolable 3). Depende del lenguaje, del framework y del tipo de proyecto.

**Si el proyecto ya tiene una carpeta de tests** (por ejemplo `test/` o `tests/`, a menudo en espejo con el código), esa es la convención:
- Cada test nuevo va dentro de esa carpeta, en la subcarpeta que refleja la ubicación del código. Por ejemplo, el test de `src/services/email.ts` va en `tests/services/email.test.ts`, no junto al código.
- Si en algún caso parece mejor otra ubicación (por la convención del lenguaje o del framework), no se decide por cuenta propia: se señala la diferencia y se pregunta.

**Si no hay ninguna carpeta ni patrón reconocible**, se pregunta en la entrevista (pregunta 20.1 de `interview.md`) o antes de la primera tarea que añada un test, con las opciones típicas del stack: carpeta dedicada en espejo, junto al archivo, o una carpeta por paquete en un monorepo.

**Dos reglas complementarias**, que se registran juntas:
- Tests unitarios (prueban una función, un componente o un módulo): siguen la convención elegida.
- Tests de integración y de extremo a extremo (cruzan varios módulos o la aplicación completa): siempre en una carpeta aparte (por ejemplo `tests/integration/` o `e2e/`), aunque los unitarios vivan junto al código, porque no pertenecen a un solo módulo.

La convención queda escrita en la sección "Pruebas" del punto de entrada. Si el proyecto ya tiene tests dispersos o mezclados con el código, se ofrece reordenarlos **como una tarea aparte**, con su plan, nunca de forma automática. El análisis inicial (`discover.sh`, sección `calidad-y-tests`) lista las carpetas de tests y los archivos de test que quedan fuera de ellas.

## 6. Escribir y ejecutar las pruebas mientras se construye

Las pruebas no se dejan para el final de la tarea (práctica conocida como *shift-left testing*: probar lo antes posible):

1. Al terminar cada parte funcional pequeña de una tarea (una función, un método, un endpoint), se escribe su test en ese momento. Es unitario si la parte está aislada, y de integración si ya conecta con otros módulos o servicios.
2. Se ejecutan ese test y los tests existentes relacionados con lo que se tocó, antes de seguir con la parte siguiente. No hace falta ejecutar toda la suite en cada paso.
3. Si algo falla, se corrige ahí mismo, mientras está claro qué se acaba de cambiar.
4. La verificación final de la tarea no cambia: la suite completa y los tests de extremo a extremo siguen ejecutándose en el control de tests, como siempre. Probar antes se suma a probar al final; no lo reemplaza.
5. La exigencia sigue el rigor acordado: en un control ligero basta el test básico de cada parte; en uno estricto se esperan también los casos límite y los errores esperados.

Esto convive con TDD (escribir el test antes que el código), si el proyecto lo usa: ambos ocurren dentro del paso de implementación y el orden de los controles de calidad no cambia (decisión abierta 7 del resumen).

## 7. Documentar la API mientras se construye (OpenAPI)

Solo aplica si el proyecto expone una API compatible con OpenAPI (por ejemplo, REST). En una librería, un script o un frontend sin backend propio no se ofrece.

1. **El documento de OpenAPI es la fuente única del contrato de la API.** Se usa la versión vigente del estándar (3.1 o la que el proyecto ya tenga). Si el framework lo genera desde el código (anotaciones, tipos, decoradores), se usa esa vía. Si no, el archivo se mantiene junto al código de los endpoints que describe.
2. **Se actualiza en la misma tarea** que crea o modifica un endpoint, no en una tarea aparte ni al final.
3. **SFP no elige la herramienta que lo muestra** (Swagger UI, Redocly, Scalar u otra): eso lo decide el proyecto. SFP solo exige un documento válido y al día.
4. **Primero se respeta lo que exista**: un documento o una herramienta ya elegida. Solo si no hay nada se pregunta (pregunta 20.2 de `interview.md`). El análisis inicial lista los archivos `openapi.*` y `swagger.*` que encuentre.
5. La revisión independiente comprueba que el documento quedó al día con el cambio, no solo que el endpoint funcione. Si el proyecto tiene un validador del documento, se añade a los controles de calidad.

## 8. Revisión independiente, también con una sola sesión

Quien revisa no es quien programó. Con varias personas, varios asistentes o un orquestador, eso es directo. Trabajando solo, con un único asistente y sin orquestador, se elige la forma según el riesgo del cambio, y **siempre se dice cuál se usó**:

| Riesgo del cambio | Revisión |
|---|---|
| Medio o alto | Revisión diferida en una **sesión nueva** (o con otro modelo o runtime, si hay), que recibe solo la spec, las tareas y los cambios, nunca la conversación donde se programó (plantilla de la sección 7 de `templates.md`). Además, se le pide a la persona que revise antes de aprobar |
| Bajo | Basta la revisión diferida en una sesión nueva |
| Trivial | Verificación básica. Si no hubo revisión independiente, el resumen lo dice: "este cambio no tuvo revisión independiente, por ser de bajo riesgo" |

Una revisión hecha en la misma conversación donde se programó **no** cuenta como independiente: se informa como autorrevisión.

Además de lo habitual (requisitos cubiertos, huecos, riesgos), la revisión comprueba:
- Que los tests nuevos están donde dice la convención del proyecto (sección 5).
- Que el documento de OpenAPI quedó al día, si el cambio tocó la API (sección 7).
- Que el README refleja el cambio, si correspondía (sección 9).
- Que toda inviabilidad declarada trae su evidencia y es del ítem en curso (secciones 3 y 4).

## 9. README vivo

El README es lo primero que lee cualquier persona o asistente nuevo. Por eso se mantiene al día junto con el proyecto, y no solo el día de la instalación.

**Formato recomendado** (si el proyecto no tiene uno propio), al estilo de un proyecto de código abierto:
- Una línea al inicio que dice qué hace el proyecto.
- Inicio rápido: el comando mínimo para empezar.
- Características principales en una tabla o lista, no en párrafos largos.
- Un diagrama simple (Mermaid) solo si ayuda a entender el flujo.
- La estructura de carpetas, en un bloque de código.
- Preguntas frecuentes, si las hay.

**Cómo se mantiene:**
- Al instalar SFP se ofrece (pregunta 20.3 de `interview.md`), como ítem del plan, una base del README con lo que ya se sabe del proyecto, aunque sea poco. Si ya existe un README, se adapta al formato sin inventar funciones que no existen y sin borrar lo que el equipo escribió. Lo que no se sepa queda marcado `PENDIENTE:`.
- En cada cambio no trivial, la spec incluye una línea "README: qué cambia o no aplica". Si hay que actualizarlo, la propuesta se muestra junto con el resto del plan del cambio y se aprueba como cualquier otra parte.
- El README nunca se reescribe por sorpresa.

## 10. Memoria del proyecto a largo plazo

Las decisiones (ADR), los procedimientos (runbooks), las lecciones y las specs archivadas se acumulan. Para que sigan siendo útiles y no se pierdan entre muchos documentos:

**Estado de cada documento.**
- ADR: `Status` es `propuesto`, `aceptado` o `reemplazado por NNNN`. Un ADR reemplazado no se borra: se conserva, y apunta al que lo reemplaza.
- Lección: `Estado` es `vigente`, `incorporada` (ya es práctica normal del equipo o pasó a una regla del punto de entrada, que se nombra) o `superada` (ya no aplica, con el motivo).
- Spec archivada: se queda en su carpeta de archivo; no se borra.

**Índices de lo vigente.** Un `README.md` en la carpeta de ADR y otro en la de lecciones, con una línea por documento **vigente** y un enlace a cada uno. Lo reemplazado o superado se lista aparte, al final. Así se encuentra la decisión que manda hoy sin leer todo el historial.

**Cuándo se revisa.**
- Al archivar un change: si el change reemplaza un ADR o vuelve obsoleta una lección, se actualiza su estado y el índice en el mismo change.
- En el modo Actualización del skill, y como máximo cada pocos meses si el equipo lo pide: se propone (no se aplica sin aprobación) marcar como incorporadas o superadas las lecciones que lo parezcan, con el motivo.

Nada se borra por antigüedad: solo cambia su estado y su lugar en el índice.
