# Metodología de trabajo: Spec-First Protocol (SFP)

Variante: sin orquestador. Fuente: la carpeta de la skill spec-first-protocol. No duplicar aquí; consultarla solo cuando haga falta.

## Flujo
- Cambio trivial (corrección puntual, ajuste de texto): implementar con verificación básica.
- Cambio no trivial (varios archivos o módulos, cambia el comportamiento, riesgo medio o alto): escribir primero la especificación en `specs/cambios/`, esperar la aprobación, implementar por tareas, verificar, revisar y archivar.

## Dónde vive cada cosa en este proyecto
- Especificaciones: `specs/cambios/`
- Decisiones (ADR): `docs/adr/`
- Lecciones aprendidas: `docs/lecciones/`
- Runbooks: no aplica por ahora

## Verificación (comandos reales)
- Pruebas: `npm test`
- Formato: `npm run lint`
- Tipos: `npm run typecheck`

## Aprobación humana obligatoria
Producción, operaciones destructivas, secretos, pagos, infraestructura crítica, eliminación masiva y cambios de la metodología.

## Git
- Commits en formato `tipo(ámbito): efecto del cambio`, con cuerpo que explica el motivo y cómo comprobarlo.
- Ramas cortas con nombre `tipo/efecto-en-pocas-palabras`, por ejemplo `feat/validar-correo-al-registrarse`.
- El asistente propone los commits y no los hace por su cuenta. Subir cambios, mezclar y borrar ramas requieren aprobación.
