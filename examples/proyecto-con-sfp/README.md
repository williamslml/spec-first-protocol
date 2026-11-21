# Proyecto de ejemplo con SFP instalado

Esta carpeta muestra cómo queda un proyecto pequeño después de instalar Spec-First Protocol y de hacer un primer cambio siguiendo la metodología. No es código real: es una referencia para ver los archivos y su contenido.

El proyecto ficticio es una tienda en línea. El cambio de ejemplo es **validar el correo electrónico** al registrar a una persona.

## Qué mirar y en qué orden

1. [INSTRUCCIONES.md](INSTRUCCIONES.md): el punto de entrada que lee el asistente al empezar. Resume el flujo, dónde vive cada cosa y qué requiere aprobación.
2. [specs/cambios/validar-correo/](specs/cambios/validar-correo/): la especificación del cambio, escrita y aprobada antes de programar. Tiene cuatro archivos: propuesta, requisitos, diseño y tareas.
3. [docs/adr/0001-validacion-en-el-servidor.md](docs/adr/0001-validacion-en-el-servidor.md): una decisión que se registró para que nadie tenga que redescubrirla.
4. [docs/lecciones/correos-con-signo-mas.md](docs/lecciones/correos-con-signo-mas.md): algo que se aprendió durante el cambio y conviene no repetir.
5. [.sfp/manifest.json](.sfp/manifest.json): el registro de lo que instaló la skill, con el que se puede verificar o retirar todo sin dañar el resto del proyecto.

## Cómo se verifica

Desde la carpeta de la skill:

```bash
sh scripts/verify.sh examples/proyecto-con-sfp
```

Comprueba que lo registrado en el manifiesto sigue en su lugar.
