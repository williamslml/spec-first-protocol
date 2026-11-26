# Revisión independiente

Tipo de revisión: sesión nueva del asistente, y además revisó una persona (el cambio es de riesgo medio).
Qué vio: la especificación, las tareas y el cambio. No vio la conversación de implementación.

## Resultado: aprobado después de un ajuste

| Hallazgo | Gravedad | Qué se hizo |
| --- | --- | --- |
| La primera versión rechazaba `ana+pedidos@ejemplo.com` | Alta | Corregido. Quedó en la prueba del requisito 2 y en la [lección aprendida](../../../docs/lecciones/correos-con-signo-mas.md) |
| El mensaje para `ana@ejemplo` hablaba de la arroba, que sí estaba | Media | Corregido: ahora dice que falta un punto en el dominio |
| El nombre `validarCorreo` es claro y la función es corta | Ninguna | Sin cambios |

## Cobertura de los requisitos

Los cuatro requisitos tienen una prueba que los comprueba, y todas pasan.

## Otras comprobaciones

- Las pruebas nuevas están en `tests/`, como acuerdan las instrucciones: sí.
- Documento de OpenAPI al día: no aplica, el proyecto no expone una API.
- README al día: no aplica, el cambio no altera cómo se instala ni se usa el proyecto.
- Inviabilidades declaradas: ninguna.
