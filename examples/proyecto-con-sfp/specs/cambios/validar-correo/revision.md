# Revisión independiente

Quién revisó: una persona (o un asistente) distinta de quien escribió el código.
Qué vio: la especificación, las tareas y el cambio. No vio la conversación de implementación.

## Resultado: aprobado después de un ajuste

| Hallazgo | Gravedad | Qué se hizo |
| --- | --- | --- |
| La primera versión rechazaba `ana+pedidos@ejemplo.com` | Alta | Corregido. Quedó en la prueba del requisito 2 y en la [lección aprendida](../../../docs/lecciones/correos-con-signo-mas.md) |
| El mensaje para `ana@ejemplo` hablaba de la arroba, que sí estaba | Media | Corregido: ahora dice que falta un punto en el dominio |
| El nombre `validarCorreo` es claro y la función es corta | Ninguna | Sin cambios |

## Cobertura de los requisitos

Los cuatro requisitos tienen una prueba que los comprueba, y todas pasan.
