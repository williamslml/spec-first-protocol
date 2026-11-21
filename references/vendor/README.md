# Contenido de terceros incluido (vendor)

Archivos copiados **sin modificar** de skills publicadas, para no reinventar prácticas ya documentadas. Cómo se aplican dentro de SFP (precedencia, reglas que mandan y contradicciones resueltas) está en `../git-practices.md`. Los archivos se renombraron de `SKILL.md` a `<nombre>.md` para que ningún runtime los cargue como skills independientes. El contenido es idéntico byte a byte.

| Archivo | Origen | Commit | Licencia | sha256 (16) |
|---|---|---|---|---|
| `addyosmani-agent-skills/git-workflow-and-versioning.md` | https://github.com/addyosmani/agent-skills · `skills/git-workflow-and-versioning/SKILL.md` | `8c99fa36d90068c82d547f7c12a9d67a3e95f4ee` (2026-11-18) | MIT, © 2025 Addy Osmani (`addyosmani-agent-skills/LICENSE`) | `d77c955f57cfafde` |
| `0xbigboss-claude-code/git-best-practices.md` | https://github.com/0xbigboss/claude-code · `.claude/skills/git-best-practices/SKILL.md` | `2921eb8a685a2589c4c3e6ecbc8eaa12ffadde73` (2026-06-24) | Apache-2.0 (`0xbigboss-claude-code/LICENSE`) | `aa1173edbbbe1b41` |
| `0xbigboss-claude-code/git-examples.md` | mismo repositorio · `.claude/skills/git-best-practices/git-examples.md` | `2921eb8a685a2589c4c3e6ecbc8eaa12ffadde73` | Apache-2.0 | `63fe62a1ec0fd0d6` |

Copiados el 2026-11-20. Las referencias internas de esos archivos a otras skills o comandos de sus repositorios (`code-review-and-quality`, `api-and-interface-design`, `deprecation-and-migration`, `shipping-and-launch`, `/rewrite-history`, `git-rebase-sync`) **no están incluidas**: `../git-practices.md` §2 indica qué hacer en su lugar.

Para comprobar que siguen sin modificar:

```sh
sha256sum addyosmani-agent-skills/git-workflow-and-versioning.md 0xbigboss-claude-code/git-best-practices.md 0xbigboss-claude-code/git-examples.md
```
