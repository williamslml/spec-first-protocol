# Los correos válidos pueden llevar signo más

- Aplica cuando: se valida o se limpia el texto de una dirección de correo.
- Problema: la primera versión de la regla rechazaba `ana+pedidos@ejemplo.com` porque solo aceptaba letras y números antes de la arroba.
- Solución: aceptar cualquier carácter antes de la arroba salvo espacios, y probar siempre con un correo con signo más.
- Evidencia: requisito 2 de `specs/cambios/validar-correo/requisitos.md`
- Recurrencia: una vez; la detectó la revisión independiente.
- Estado: vigente.
