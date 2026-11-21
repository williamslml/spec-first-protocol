# Política de seguridad

## Versiones con soporte

Solo se corrigen problemas de seguridad en la versión más reciente. Se indica en la insignia del [README](README.md) y en la sección de releases.

## Cómo reportar una vulnerabilidad

**No abrir un issue público.** Un reporte público expondría el problema antes de que exista una corrección.

Usar el reporte privado de GitHub:

1. Entrar a la pestaña **Security** de la página principal del repositorio.
2. Elegir **Report a vulnerability** (el nombre puede variar según el idioma de GitHub).
3. Describir el problema con el mayor detalle posible: qué ocurre, cómo reproducirlo y qué impacto podría tener.

El reporte solo lo ven los mantenedores. Se intentará responder en una semana, y se acordará con la persona que reporta cómo y cuándo se publica la corrección.

## Qué se considera un problema de seguridad aquí

Esta skill ejecuta scripts en el equipo de quien la usa y puede instalar herramientas de terceros, por eso interesan sobre todo:

- Un script que ejecute comandos no previstos o que borre o modifique archivos sin la aprobación del usuario.
- El instalador de herramientas complementarias descargando o ejecutando algo que no está en las versiones fijadas.
- La exposición de contraseñas, tokens u otras credenciales en una salida, un archivo generado o un mensaje.
- El filtro de firmas de commits modificando partes del mensaje que no debe.
- Instrucciones de la metodología que lleven a un asistente a una acción destructiva sin pedir aprobación.

## Qué no corresponde reportar aquí

- Problemas en las herramientas de terceros que la skill puede instalar (Superpowers, Serena, RTK, archify, frontend-design, uv o el CLI `skills`). Se reportan a cada proyecto.
- Errores sin impacto de seguridad. Para esos, usar un [issue](../../issues/new/choose).
