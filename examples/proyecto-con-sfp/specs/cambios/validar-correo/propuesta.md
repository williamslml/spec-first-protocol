# Propuesta: validar el correo al registrarse

Estado: aprobada por la persona responsable del producto.

## Problema
Hoy el registro acepta cualquier texto en el campo de correo. Eso llena la base de datos de direcciones inservibles, y los avisos de pedido nunca llegan a esas personas.

## Qué se propone
Rechazar el registro cuando el correo no tiene una forma válida, y mostrar un mensaje claro para que la persona lo corrija.

## Qué no se incluye
- Comprobar que el buzón existe enviando un mensaje de verificación.
- Limpiar las direcciones inválidas que ya están guardadas.

## Riesgo
Bajo. Solo afecta al formulario de registro. Si falla, se puede volver a la versión anterior sin perder datos.
