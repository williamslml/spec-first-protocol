# Diseño

## Dónde se valida
En el servidor, dentro de `src/registro.js`. El formulario del navegador también avisa, pero solo como ayuda: la regla que manda es la del servidor. La razón está en la decisión [0001](../../../docs/adr/0001-validacion-en-el-servidor.md).

## Cómo se valida
Una función `validarCorreo(texto)` que devuelve `{ valido, motivo }`. El registro la llama antes de guardar y, si no es válido, responde con el motivo.

## Alternativas descartadas
- Usar una biblioteca externa de validación: agrega una dependencia para una regla de tres condiciones.
- Validar solo en el navegador: cualquiera puede saltarse esa comprobación.
