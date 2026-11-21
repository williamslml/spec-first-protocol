# 0001. La validación del correo manda en el servidor

- Status: aceptado
- Context: el formulario puede avisar al instante si el correo está mal escrito, pero esa comprobación se puede saltar con una herramienta cualquiera.
- Decision: la regla definitiva se aplica siempre en el servidor. La del navegador es solo una ayuda para la persona.
- Alternatives: validar solo en el navegador (más rápido, pero no protege los datos); validar en ambos lados con reglas separadas (riesgo de que se contradigan).
- Consequences: hay que mantener una sola regla y reutilizar su mensaje en el formulario. Cualquier otra forma de registrarse, como una importación masiva, también queda protegida.
- References: `specs/cambios/validar-correo/diseno.md`
