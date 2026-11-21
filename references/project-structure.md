# Estructura de carpetas del proyecto, por etapas

Propuesta por proyecto, no regla global (sección 1 de `architecture.md`). En la Fase 2 (pregunta 5.1) se eligen perfil (tipo de proyecto) y etapa (cuánta estructura necesita hoy) según la sección 3; en la Fase 4 va como punto del plan; solo se aplica tras aprobarse en la Fase 5. Si el framework impone su organización (Next.js `app/`, Rails, etc.), manda sobre el perfil. Cómo comprobar que la regla de dependencia se cumple de verdad y no solo en el papel: `references/structure-verification.md`.

## 0. Reglas comunes a los 8 perfiles

- Carpetas por funcionalidad (*feature*) o módulo primero, no por capa técnica (`controllers/`, `services/`, `models/` repetidos en primer nivel).
- Cada feature/módulo expone su API pública por un único punto de entrada (archivo índice o carpeta `public/`); el resto es interno y no se importa de fuera.
- Declarar la regla de dependencia de cada perfil (qué puede importar qué; tabla de la sección 1) y verificarla (`structure-verification.md`); sin verificación es solo documentación.
- No pasar a Etapa 2 sin cumplir la condición de su fila.
- Carpetas en minúsculas y en plural para colecciones (`features/`, `modules/`, `packages/`). Cada feature en kebab-case o snake_case (guion o guion bajo), según lo ya usado en el proyecto; nunca ambos en el mismo repo.
- Migrar de Etapa 1 a Etapa 2 (si mueve código existente, combinar con la sección 3 de `scenarios.md`):
  1. Mapa antes → después por carpeta/archivo.
  2. Mover un módulo a la vez, conservando el historial (`git mv`) y comprobando compilación y pruebas tras cada uno.
  3. Actualizar imports, config de compilación y CI (integración continua) de cada módulo movido.
  4. Ejecutar la verificación de dependencias (`structure-verification.md`) sobre el resultado antes de cerrar la migración.
  5. Registrar la decisión como ADR (decisión de arquitectura documentada) en `docs/adr/` (Status/Context/Decision/Alternatives/Consequences/References), citando la condición que la justificó.

## 1. Perfiles: referencia rápida

| Perfil | Etapa 1: crear | Pasar a Etapa 2 cuando | Etapa 2: crear | Regla de dependencia |
|---|---|---|---|---|
| API / Backend | Una carpeta por feature/recurso (`features/orders/`) con rutas, lógica y acceso a datos juntos; `shared/` solo para auth/config/errores | Más de ~8–10 features · reglas de negocio cruzan varias features · hay que probar la lógica sin el framework web | Separar capas en cada feature (rutas/handlers → casos de uso → datos), o hexagonal (puertos/adaptadores: núcleo aislado del framework y la base de datos) si el dominio lo exige | Las features no se importan entre sí; solo vía `shared/`. El acceso a datos de una feature no se expone fuera de ella |
| Frontend | Por feature/página (`features/checkout/`) con componentes, hooks (lógica reutilizable) y estado juntos; `shared/`/`ui/` solo lo ya usado en 2+ features | Un componente/hook se repite en 3+ features sin estar en `shared/` · aparece un sistema de diseño (design system) propio · el bundle (paquete final) crece sin code-splitting (carga por partes) | Paquete `ui/`/`design-system/` real; separar la lógica (hooks/estado) de los componentes si la feature es compleja | Una feature no importa componentes internos de otra; solo lo publicado en `shared/ui/` |
| Fullstack | Una carpeta por feature que cruza interfaz + lógica + datos, respetando la convención de rutas del framework | Frontend y backend se despliegan o escalan aparte · los mantienen equipos distintos | Separar en dos proyectos (o dos workspaces de un monorepo: ver perfil Monorepo), mismo criterio por feature en cada uno | La parte de frontend de una feature no accede directo a la base de datos; pasa por la capa de API de esa feature |
| Monorepo | Un workspace (subproyecto del repo) por app/servicio desplegable + `packages/` solo con lo compartido de verdad; workspaces del gestor (pnpm/turbo/nx/lerna), nunca enlaces simbólicos manuales | Dos apps duplican el mismo código en vez de compartirlo · un paquete compartido tiene consumidores con necesidades incompatibles | Paquetes compartidos con compilación/versión internas propias; mapa de dependencias entre apps y paquetes explícito y sin ciclos | Una app nunca importa el código interno de otra app; solo un paquete publicado en `packages/` |
| Librería / SDK | `src/` con un único punto de entrada público (`index`); el resto, interno según la convención del lenguaje (`_internal/`, o no exportado en el índice) | La librería crece a módulos que conviene importar aparte (tree-shaking: cargar solo lo usado) · aparecen adaptadores por entorno (node/browser/edge) | Rutas de exportación (subpaths) explícitas (`lib/core`, `lib/adapters/node`), cada una con su API documentada | Nada fuera de `src/index` (o los subpaths declarados) es contrato público; romperlo es un cambio incompatible (*breaking change*) y exige ADR + versión mayor |
| Datos / ML | Por etapa del pipeline (cadena de procesamiento: `ingest/`, `features/`, `train/`, `evaluate/`, `serve/`); notebooks de exploración en `notebooks/`, aparte del código productivo | Un notebook pasa a ser fuente de lógica que corre en producción · varios modelos/pipelines comparten pasos | Extraer los pasos compartidos a una librería interna (`common/` o paquete del monorepo); `serve/` deja de depender de notebooks | `serve/` no depende de `notebooks/`; toda lógica que `serve/` necesita vive en `src/` |
| Móvil | Por feature/pantalla (`features/login/`, interfaz + estado + red juntos), con la convención del framework (módulos Gradle, grupos Xcode, carpetas RN/Flutter) | Una feature necesita compilarse/probarse aislada · la compilación tarda demasiado · aparece un segundo destino de compilación (tablet, reloj, extensión) | Módulos de compilación reales por feature si el framework lo permite; código compartido entre destinos en `core/`/`shared` | Una feature no importa directo la pantalla de otra; navegación y datos compartidos pasan por `core/` |
| Infraestructura / DevOps | Por ambiente, combinando módulos compartidos de `modules/` (`envs/staging/`, `envs/prod/`) | Dos ambientes divergen con código copiado en vez de parametrizado · aparece otra cuenta/proyecto en la nube que necesita la misma base | Módulos con versión independiente (p. ej. de Terraform, con registro/versión propios) que cada ambiente usa con entradas distintas | Un ambiente nunca usa directo el estado de otro; lo compartido vive en `modules/`, parametrizado |

## 2. Detalle por perfil

### 2.1 API / Backend

```
src/
├── features/
│   ├── orders/
│   │   ├── orders.routes.<ext>       # entrada pública de la feature
│   │   ├── orders.service.<ext>      # lógica
│   │   ├── orders.repository.<ext>   # acceso a datos (interno)
│   │   └── orders.types.<ext>
│   └── users/
│       └── ...
└── shared/
    ├── auth/
    ├── config/
    └── errors/
```
- **Casos:** REST: una carpeta por recurso, como arriba. GraphQL: añadir `*.resolvers.<ext>` y `*.schema.graphql` dentro de cada feature. El esquema combinado vive en `shared/graphql/`; nunca se escribe a mano fuera de las features. Por eventos (colas, publicación/suscripción): añadir `*.consumer.<ext>`/`*.producer.<ext>` dentro de la feature dueña del evento. Los eventos cruzan features solo por nombre/contrato, sin importar el `consumer` de otra feature.
- **Nombres:** sufijo por tipo de archivo (`.routes`, `.service`, `.repository`), sin carpetas por capa en Etapa 1.
- **Etapa 2 (hexagonal):** `features/orders/{domain,application,infrastructure}/`. `domain/` sin dependencias externas; `infrastructure/` es lo único que importa el framework o la base de datos.

### 2.2 Frontend

```
src/
├── features/
│   └── checkout/
│       ├── components/
│       ├── hooks/
│       ├── checkout.state.<ext>
│       └── index.<ext>               # API pública de la feature
└── shared/
    └── ui/
        ├── Button/
        └── Modal/
```
- **Casos:** App de una sola página (SPA): como arriba. Renderizado en servidor/meta-framework (Next.js, Nuxt, Remix): las rutas van donde el framework exige (`app/`, `pages/`); `features/` tiene la lógica y los componentes que esas rutas importan, nunca al revés. Micro-frontends: cada uno es un perfil Frontend completo; lo compartido sigue la regla del perfil Monorepo.
- **Nombres:** un componente por carpeta, en PascalCase (CadaPalabraConMayúscula); hooks con prefijo `use`.
- **Etapa 2:** `shared/ui/` pasa a ser un paquete real (`packages/ui` si ya es monorepo) con su `package.json`/compilación, no una carpeta importada por ruta relativa.

### 2.3 Fullstack

```
app/                                   # o `pages/`, según el framework
└── checkout/
    ├── page.<ext>                     # convención del framework
    ├── checkout.actions.<ext>         # lógica de servidor de la feature
    ├── checkout.client.<ext>          # lógica de cliente de la feature
    └── checkout.repository.<ext>      # acceso a datos (solo lado servidor)
```
- **Casos:** Framework con server actions/loaders (código de servidor junto a la ruta: Next.js App Router, Remix, SvelteKit): como arriba. Backend separado en el mismo repo, sin meta-framework: tratarlo como dos perfiles (API + Frontend) bajo `apps/` si ya hay o habrá más de un desplegable (ver 2.4).
- **Nombres:** sufijo `.client`/`.server` (o el que use el framework) para dejar claro qué corre dónde.
- **Etapa 2:** mover a `apps/web/` y `apps/api/` (perfil Monorepo), conservando `checkout/` como feature dentro de cada uno.

### 2.4 Monorepo

```
apps/
├── web/
└── api/
packages/
├── ui/
└── config/
```
- **Casos:** Un lenguaje (todo JS/TS): un gestor de workspaces (pnpm/turbo/nx). Varios lenguajes (p. ej. frontend TS + backend Go): cada `apps/<nombre>` es autónomo en su lenguaje. `packages/` solo para lo que de verdad cruza lenguajes (contratos/esquemas), nunca código compilado de un lenguaje usado por otro sin una capa explícita de serialización (paso a un formato común).
- **Nombres:** `apps/<nombre-desplegable>`, `packages/<nombre-del-paquete>`; el nombre del paquete publicado (en su manifiesto) coincide con la carpeta.
- **Etapa 2:** cada paquete de `packages/` tiene su propio changelog/versión. Un paquete usado por un solo `app` no debería existir: si pierde a sus otros consumidores, vuelve dentro de ese app.

### 2.5 Librería / SDK

```
src/
├── index.<ext>                        # único punto de entrada público
├── core/
└── _internal/                          # nunca exportado en index
```
- **Casos:** Librería de un solo entorno: como arriba. SDK para varios entornos (node + browser + edge): `src/adapters/{node,browser,edge}/`, cada uno exportado como subpath propio desde la Etapa 2. `src/core/` no importa ningún adaptador.
- **Nombres:** el nombre del subpath de exportación (`lib/adapters/node`) coincide con la ruta real; no exponer rutas internas como `lib/src/internal/x`.
- **Etapa 2:** el `package.json`/manifiesto declara los `exports` explícitos; una ruta no declarada ahí no es pública aunque el archivo exista.

### 2.6 Datos / ML

```
src/
├── ingest/
├── features/
├── train/
├── evaluate/
└── serve/
notebooks/                              # exploración; nunca importado por src/
```
- **Casos:** Por lotes (pipelines programados): como arriba, orquestado por el programador de tareas del proyecto. En tiempo real (baja latencia): `serve/` no depende de `train/` al ejecutarse; el modelo entrenado se usa como artefacto con versión (ruta o registro de modelos), nunca importando el código de `train/`.
- **Nombres:** un notebook por experimento, con fecha o ticket en el nombre; el validado se reescribe como módulo en `src/` antes de usarse en producción.
- **Etapa 2:** `common/` (o un paquete del monorepo) con lo compartido entre `ingest/`, `train/` y `serve/`; ninguno de los tres importa directamente de otro.

### 2.7 Móvil

```
features/
└── login/
    ├── LoginScreen.<ext>
    ├── LoginViewModel.<ext>
    └── LoginRepository.<ext>
core/
└── navigation/
```
- **Casos:** Nativo (Android e iOS por separado): `features/<feature>/` dentro de cada proyecto nativo, con el nombre de módulo/target que use Gradle o Xcode. Multiplataforma (RN/Flutter/KMP): `features/<feature>/` compartida; solo lo propio de cada plataforma baja a `platform/{android,ios}/` dentro de la feature.
- **Nombres:** sufijo por capa dentro de la feature (`Screen`, `ViewModel`/`Bloc`, `Repository`); en Etapa 1, no carpetas separadas.
- **Etapa 2:** cada feature grande pasa a ser su propio módulo de compilación (módulo Gradle, Swift Package, o paquete del monorepo de RN/Flutter).

### 2.8 Infraestructura / DevOps

```
envs/
├── staging/
│   └── main.<ext>                      # compone módulos con inputs de staging
└── prod/
    └── main.<ext>
modules/
├── network/
└── database/
```
- **Casos:** Una sola cuenta/proyecto en la nube: como arriba. Varias (p. ej. por cliente o región): un `envs/<cuenta>/<ambiente>/` adicional por cada una, todas con los mismos `modules/`.
- **Nombres:** el nombre del ambiente en la carpeta coincide con el nombre real del workspace/estado remoto (nunca duplicarlo con otro nombre en el código).
- **Etapa 2:** cada módulo de `modules/` se publica con versión propia (registro de módulos de la herramienta); los `envs/*` fijan la versión que usan, no `latest`.

## 3. Cómo se deciden perfil y etapa

Igual que los roles de agente (sección 7 de `architecture.md`): partir de hechos, proponer con justificación y que el usuario decida. Nunca se aplica solo. Peso de la evidencia: convención del framework > hechos del proyecto (`discover.sh`, script de análisis, y el código real) > respuestas de la entrevista > valor por defecto (Etapa 1).

**Paso 0. Estado actual del proyecto.** Primero, ubicar el proyecto en una de estas situaciones. Los datos salen de la sección `estructura-de-codigo` de `discover.sh` (no se cuentan a mano) y del caso elegido de `scenarios.md`:

| Señal de `discover.sh` | Cómo se lee |
|---|---|
| `features_max` | Nº de features/módulos existentes (subcarpetas de la `features/` o `modules/` más poblada). Es la cifra que usa el paso 2 |
| `raices_de_codigo … clasificacion=` | `por-capas` (≥2 carpetas de capa y son al menos la mitad del primer nivel) · `mixto` (≥2 de capa, pero minoría) · `por-feature` (hay `features/`/`modules/` y <2 de capa) · `indeterminado` |
| `convencion_de_framework` | Si hay alguna línea, esa convención manda (fila 2 de la tabla siguiente) en el workspace donde aparece |
| `desplegables_estimados` y `contenedores_de_workspaces` | Nº de unidades desplegables (`apps/*`, `services/*`, subproyectos de primer nivel con manifiesto). Es la cifra que usan el paso 2 y las reglas de desempate (sección 3.1) |
| `pistas` | `package_json_exports`, `archivos_tf`, `notebooks_ipynb`, `dirs_movil`, `dirs_envs`: candidatos Librería, Infra, Datos/ML, Móvil (paso 3) |

Si `discover.sh` no se pudo ejecutar, estas cifras salen de la checklist manual de `scenarios.md`, y el plan dice que se contaron a mano.


| Situación | Qué significa para perfil y etapa |
|---|---|
| Nuevo / vacío (caso 2) | Nada que respetar: decide la entrevista (pasos 1–2). Sin datos de escala, Etapa 1 anotada como revisable |
| Existente con convención de framework (`convencion_de_framework` no vacío) | Manda el framework. El perfil se adapta a esa convención y no mueve nada; la etapa se evalúa igual |
| Existente ya organizado por feature/módulo (`clasificacion=por-feature`) | Adoptar: el perfil describe lo que ya hay, no lo cambia. La etapa sale de la condición real; no se proponen movimientos |
| Existente por capas técnicas en primer nivel (`clasificacion=por-capas` o `mixto`) | El perfil es el destino, no una orden. En los casos 1 y 4 no se mueve el código antiguo: se registra la brecha y las features nuevas siguen el perfil. Mover código solo en el caso 3, pedido explícitamente (sección 0, migración). Si la herramienta de verificación lo permite, registrar las violaciones ya existentes como línea base; si no, dejar `verify_command` en `PENDIENTE` |
| Existente que ya cumple la condición de Etapa 2 | Proponer Etapa 2 como recomendación. Aplicarla solo si el usuario pidió reestructurar código (caso 3 + pasos de migración de la sección 0); si no, queda anotada como revisable, no como acción del plan |
| Caso 4 (solo metodología, sin tocar carpetas) | `profile: ninguno` por defecto (sin `stage`, o `n/a`). Se puede dejar el perfil en `rationale` como referencia, sin instalar estructura ni verificación |
| Ya existe `.sfp/manifest.json` (modo Actualización) | No re-preguntar desde cero: leer `structure.profile`/`stage`, reevaluar la condición de Etapa 2 con los datos de hoy y proponer solo el cambio (delta; ver paso 6) |

**Pasos:**

1. **Tipo (pregunta 5) → perfil candidato.** Correspondencia directa:

   | Respuesta a la pregunta 5 | Perfil |
   |---|---|
   | web frontend | Frontend |
   | backend/API | API / Backend |
   | fullstack | Fullstack |
   | móvil | Móvil |
   | datos/ML | Datos / ML |
   | librería/SDK | Librería / SDK |
   | infraestructura/DevOps | Infraestructura / DevOps |
   | monorepo | Monorepo |
   | otro | Sin correspondencia directa: preguntar a qué se parece más o usar `ninguno` |

   Si el tipo es ambiguo (varios servicios, front y back en el mismo repo), los candidatos se resuelven con las reglas de desempate de la sección 3.1, no con el criterio del agente.
2. **Escala (pregunta 5.1) → etapa.** Comparar la escala de hoy (no la de "algún día") con la columna "Pasar a Etapa 2 cuando" de la fila del perfil. Si ya se cumple al menos una condición → Etapa 2; si no → Etapa 1. Si el usuario no sabe, Etapa 1 anotada como revisable. Las cifras de `discover.sh` pesan más que la estimación a futuro; las condiciones numéricas se leen siempre así:

   | Condición | Cifra | No se cumple | Zona límite | Se cumple |
   |---|---|---|---|---|
   | API: "más de ~8–10 features" | `features_max` | ≤ 7 | 8–10: Etapa 1 anotada como revisable, salvo que se cumpla otra condición de la fila | ≥ 11 |
   | Frontend: "se repite en 3+ features" | lo confirma el usuario o una búsqueda en el código | < 3 | — | ≥ 3 |
   | Fullstack / Monorepo: "se despliegan por separado" | `desplegables_estimados` | 1 | — | ≥ 2 (confirmado por el usuario: un manifiesto no prueba despliegue) |

   Las condiciones no numéricas ("reglas de negocio cruzan features", "equipos distintos") se preguntan con sí/no; "no sé" = no se cumple, anotado como revisable.
3. **Contrastar con el análisis (discovery).** Los hechos pesan más que la respuesta libre. Ej.: `pnpm-workspace.yaml`, `turbo.json`, `nx.json` o varios manifiestos en `apps/`/`packages/` → candidato Monorepo aunque el usuario diga otra cosa; `package.json` con `exports` y sin app desplegable → Librería/SDK; `*.tf` → Infraestructura. Si hay contradicción, mostrarla al usuario, no elegir en silencio.
4. **Presentar, no aplicar.** Formato fijo: "Perfil propuesto: X · Etapa: Y · Situación actual: Z · Porque <tipo + condición cumplida o no>". Mostrar también la alternativa más simple (Etapa 1 o `ninguno`). El usuario acepta, cambia de perfil, fuerza otra etapa o usa su propia estructura; un cambio suyo se respeta y se anota como decisión del usuario, no del skill.
5. **Registrar.** En el plan de la Fase 4 va con la justificación completa (situación del paso 0 y, si hubo empate, la regla de la sección 3.1 que lo resolvió). En `manifest.json.structure` va lo aprobado al final: `profile`, `stage`, `rationale` (una línea) y `verify_command`; con perfil `monorepo`, además la lista `workspaces` (sección 3.2).
6. **Revisión posterior (modo Actualización).** Con manifiesto existente, repetir solo los pasos 2–3 con datos actuales:
   - Si `stage: 1` y ahora se cumple una condición de Etapa 2 → proponer la migración (con ADR, sección 0), sin ejecutarla.
   - Si `stage: 2`, no bajar de etapa: solo avisar si la condición ya no se cumple.
   - Si cambió el perfil de fondo (p. ej. un proyecto único pasó a monorepo), tratarlo como reestructuración (sección 3 de `scenarios.md`).

### 3.1 Reglas de desempate entre perfiles

Se aplican en orden; decide la primera que encaja. Cada una indica la señal de `discover.sh` que la activa. El resultado se presenta como propuesta (paso 4) con la regla usada; si el usuario lo cambia, se registra como suya.

| # | Situación | Señal | Perfil |
|---|---|---|---|
| D1 | Front y back en el mismo repo **con** meta-framework que sirve ambos (server actions/loaders/API routes) | `convencion_de_framework` = next, nuxt, remix, svelte/sveltekit, astro… y `desplegables_estimados` = 1 | **Fullstack**, aunque exista una carpeta `api/` dentro del framework |
| D2 | Front y back en el mismo repo **sin** meta-framework, con 2+ desplegables | `desplegables_estimados` ≥ 2 (p. ej. `frontend/` + `backend/`, `client/` + `server/`, `apps/web` + `apps/api`) | **Monorepo**, con un workspace API y uno Frontend (sección 3.2). Si hoy no están bajo `apps/`, no se mueven salvo caso 3: los workspaces se registran con su ruta real |
| D3 | Front y back sin meta-framework y un solo desplegable (p. ej. un servidor que también sirve la SPA desde el mismo manifiesto) | `desplegables_estimados` = 1 | **Fullstack** Etapa 1 (caso "backend separado sin meta-framework" de la sección 2.3); la condición de Etapa 2 es que pasen a desplegarse por separado (→ D2) |
| D4 | Proyecto nuevo sin código y el usuario no sabe si front y back se desplegarán por separado | sin cifras | **Fullstack** Etapa 1 anotada como revisable (la alternativa más simple); se reevalúa con D2 en modo Actualización |
| D5 | Una app móvil y su backend en el mismo repo | `dirs_movil`, o `flutter/dart`/`react-native`/`gradle`/`xcode` en `convencion_de_framework`, + otro desplegable | **Monorepo** (workspace Móvil + workspace API): siempre son desplegables distintos |
| D6 | Librería con app de ejemplo/demo/docs | `package_json_exports: si` (o equivalente del lenguaje) y la app está en `examples/`, `demo/` o `docs/` | **Librería / SDK**; la demo no cuenta como desplegable |
| D7 | Infraestructura como código dentro del repo de una app | `archivos_tf` > 0 o `dirs_envs`, junto a una app | El perfil de la app. La carpeta de infra sigue las reglas del perfil Infra como sub-área, anotado en `rationale`. Pasa a workspace propio (→ Monorepo) solo con varios ambientes y ciclo de despliegue propio |
| D8 | Datos/ML con servicio de inferencia (predicciones) | `notebooks_ipynb` > 0 o carpetas de pipeline, + una API | Si la API es la etapa `serve/` del mismo pipeline → **Datos / ML**. Si es otra app que usa modelos con versión → **Monorepo** (workspace Datos/ML + workspace API) |
| D9 | Varios desplegables del mismo tipo (p. ej. tres APIs) | `contenedores_de_workspaces` | **Monorepo**; cada workspace con su perfil (todos API) |
| D10 | Ninguna anterior encaja y siguen dos candidatos | — | El de menos estructura (Etapa 1 del más simple, o `ninguno`), mostrando el otro como alternativa |

Las señales del análisis ganan a la respuesta libre (paso 3): si el usuario dice "es una sola app" y hay `desplegables_estimados` ≥ 2, se muestra la contradicción antes de aplicar D1–D10.

### 3.2 Monorepo con varios perfiles (un perfil y una etapa por workspace)

En un Monorepo la regla de dependencia del repo (entre apps y paquetes) es una, pero cada workspace desplegable tiene su propio tipo y escala. Procedimiento:
1. Listar los workspaces desde `contenedores_de_workspaces` y `subproyectos_de_primer_nivel_con_manifiesto` (o los que declare el gestor de workspaces).
2. Para cada workspace desplegable, repetir los pasos 0–4 de la sección 3 **dentro de ese workspace**: su perfil (API, Frontend, Fullstack, Móvil, Datos/ML, Infra, Librería) y su etapa, con sus cifras (`features_max` y `clasificacion` de su `src/`). Un workspace no puede tener perfil `monorepo`.
3. Los paquetes compartidos (`packages/*`, `libs/*`) se registran como workspaces con perfil `libreria-sdk` solo si el usuario quiere verificarlos por separado; si no, los cubre la regla del Monorepo.
4. La etapa del repo (`structure.stage`) es la del perfil Monorepo (sección 1, fila Monorepo); la de cada workspace va en su entrada.
5. Se presenta como tabla: `Workspace | Perfil | Etapa | Situación actual | Porque`. El usuario puede aceptar la tabla entera o fila por fila.
6. En `manifest.json.structure.workspaces` (sección 1 de `templates.md`) va una entrada por workspace con `path`, `profile`, `stage`, `rationale` y `verify_command` propio (o `PENDIENTE`). `scripts/verify.sh` valida cada entrada y que su ruta exista.

En modo Actualización, el paso 6 de la sección 3 se repite por workspace; uno nuevo es un cambio a proponer, no una reinstalación.

## 4. Dónde se usa en el flujo del skill

- Fase 2, pregunta 5.1 (`interview.md`): aporta la escala; perfil y etapa se deciden según la sección 3.
- Fase 4: perfil y etapa van como punto del plan, con la condición que aplica o la razón para quedarse en Etapa 1. Incluir qué verificación de dependencias (`structure-verification.md`) se instalará, si alguna.
- Fase 5: si el usuario prefiere otra estructura, se usa la suya; el perfil es una sugerencia, no una imposición.
- Fase 7: si se eligió perfil, `scripts/verify.sh` comprueba la coherencia del registro y muestra el `verify_command`; la regla de dependencia se ejecuta con `--run-verify` tras la aprobación del usuario (`structure-verification.md`).
- Proyecto existente que ya cumple la condición de Etapa 2: tratar según la sección 3 de `scenarios.md` (reestructurar), con mapa antes → después y los pasos de migración de la sección 0.
