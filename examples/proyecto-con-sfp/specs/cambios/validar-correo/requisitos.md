# Requisitos

1. El registro debe rechazar un correo que no tenga un texto antes y después de una arroba, y un dominio con al menos un punto.
2. El registro debe aceptar correos con signo más, como `ana+pedidos@ejemplo.com`.
3. Cuando el correo no es válido, el mensaje debe decir qué corregir, por ejemplo "Revisa el correo: falta la arroba".
4. Un correo válido debe seguir registrándose igual que antes, sin pasos adicionales.

## Cómo se comprueba cada uno

| Requisito | Comprobación |
| --- | --- |
| 1 | Prueba con `sin-arroba.com`, `@ejemplo.com` y `ana@ejemplo`: las tres deben rechazarse |
| 2 | Prueba con `ana+pedidos@ejemplo.com`: debe aceptarse |
| 3 | Prueba que el mensaje de error nombra el problema |
| 4 | Las pruebas de registro que ya existían siguen pasando |
