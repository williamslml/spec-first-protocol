#!/bin/sh
# commit-msg-ai-attribution.sh — fuente única del filtro de atribución de agentes de IA
# (references/templates.md sección 17). POSIX sh + awk: funciona con Git for Windows, Linux, macOS y BusyBox.
#
# Dos usos, el mismo código:
#   1. Como hook: copiar el bloque entre "sfp:start" y "sfp:end" al hook commit-msg del proyecto
#      (con el id de su acción del manifiesto). Si el hook no existe, crearlo con la línea #!/bin/sh.
#   2. Como script versionado (gestores de hooks: lefthook, pre-commit…):
#        sh .sfp/hooks/commit-msg-ai-attribution.sh <archivo-del-mensaje>
#
# Qué quita (agnóstico: cualquier agente de la lista, no solo uno):
#   - Trailers Co-Authored-By cuyo nombre o correo es de un agente de IA.
#   - Líneas tipo "Generated with/by …" o "Created with …" que nombran a un agente.
#   - Trailers cuya clave nombra a un agente (p. ej. "Claude-Session: …").
# Qué NO toca:
#   - El asunto (primera línea), los co-autores humanos, Signed-off-by, y los trailers de divulgación
#     explícita como Assisted-by (si la política del proyecto exige declarar la IA, no instalar esto).
# Desactivar en un commit concreto:  SFP_KEEP_AI_ATTRIBUTION=1 git commit …
# Ampliar la lista: añadir nombres o dominios a SFP_AI_NAMES / SFP_AI_DOMAINS (en minúsculas).

# sfp:start v1 id=N
# Spec-First Protocol: quita la atribución automática de agentes de IA del mensaje (templates.md sección 17).
if [ -z "${SFP_KEEP_AI_ATTRIBUTION:-}" ] && [ -f "$1" ]; then
  SFP_AI_NAMES='claude|claude code|anthropic|copilot|github copilot|copilot-swe-agent|cursor agent|cursoragent|codex|openai codex|chatgpt|gemini|gemini code assist|google-labs-jules|aider|devin ai|devin-ai-integration|windsurf|codeium|amazon q|codewhisperer|openhands|tabnine|qwen code|deepseek|grok'
  SFP_AI_DOMAINS='anthropic[.]com|cursor[.]com|cursor[.]sh|aider[.]chat|openai[.]com|all-hands[.]dev|devin[.]ai|codeium[.]com|windsurf[.]com'
  awk -v names="$SFP_AI_NAMES" -v domains="$SFP_AI_DOMAINS" '
    BEGIN {
      ai  = "(^|[^a-z0-9])(" names ")([^a-z0-9]|$)"
      dom = "@[^>]*(" domains ")"
    }
    {
      line = $0; sub(/\r$/, "", line); l = tolower(line)
      if (NR > 1) {
        if (l ~ /^[ \t]*co-authored-by:/ && (l ~ ai || l ~ dom)) next
        if (l ~ /(generated|created|made|written|authored) (with|by|using)/ && l ~ ai) next
        if (match(l, /^[a-z0-9]+-[a-z0-9-]*:/) && substr(l, 1, RLENGTH) ~ ai) next
      }
      out[++n] = $0
    }
    END {
      while (n > 0 && out[n] ~ /^[ \t\r]*$/) n--
      for (i = 1; i <= n; i++) print out[i]
    }' "$1" > "$1.sfp-tmp" && mv "$1.sfp-tmp" "$1" || rm -f "$1.sfp-tmp"
fi
# sfp:end id=N
