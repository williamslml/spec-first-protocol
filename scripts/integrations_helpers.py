#!/usr/bin/env python3
"""Ayudantes de integrations.sh para leer y fusionar JSON/TOML sin dependencias externas.

Solo biblioteca estándar. Cada subcomando sale con 0 = sí/hecho, 1 = no/ausente,
2 = error de uso o de datos, 3 = no se puede comprobar (p. ej. Python < 3.11 sin tomllib).
Nunca sobrescribe datos ajenos: las fusiones añaden o quitan solo lo propio y validan el
resultado antes de reemplazar el archivo (escritura atómica con os.replace).

Subcomandos:
  plugin-enabled <nombre> <json...>          ¿plugin habilitado/instalado? imprime dónde
  mcp-entry <.mcp.json> <~/.claude.json> <proyecto> <nombre>
                                             imprime "<ámbito>\\t<comando y args>" de la entrada MCP
  mcp-add <.mcp.json> <nombre> <comando> [args...]
                                             añade la entrada si no existe (idempotente)
  mcp-remove <.mcp.json> <nombre> <comando> [args...]
                                             la quita solo si coincide exactamente (1 si difiere)
  oc-mcp-entry <opencode.json> <nombre>     imprime el comando de la entrada MCP de OpenCode (1.x o 2.x)
  oc-mcp-add <opencode.json> <major> <nombre> <comando...>
                                             la añade con el formato de esa versión de OpenCode
  oc-mcp-remove <opencode.json> <nombre> <comando...>
                                             la quita solo si el comando coincide (1 si cambió)
  hook-has <settings.json> <Evento> <texto>  ¿algún hook de <Evento> ejecuta un comando con <texto>?
  env-has <settings.json> <VARIABLE> <texto> ¿env.<VARIABLE> contiene <texto>?
  toml-list <check|apply|remove> <config.toml> <tabla> <clave> <valor...>
                                             comprueba, añade o quita valores de una lista TOML
  block-has <archivo> <marca-inicio>         ¿el archivo contiene la marca?
  block-remove <archivo> <marca-inicio> <marca-fin>
                                             quita el bloque entre marcas (incluidas)
  state-select <estado.json>                 imprime la selección guardada como líneas clave=valor
  state-save <estado.json> <only> <skip> <scope> <rtk_scope> <force_frontend> <versión> [<agente> [<runner>]]
  state-add <estado.json> <componente> <ámbito> <tipo> <auto:0|1> <objetivo> <deshacer>
  state-list <estado.json>                   registros: idx\\tcomp\\támbito\\ttipo\\tauto\\tobjetivo\\tdeshacer
  state-drop <estado.json> <idx...>          quita registros; borra el archivo si no queda ninguno
"""
import datetime
import json
import os
import re
import sys


def load_json(path):
    if not os.path.isfile(path):
        return {}
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def load_json_lenient(path):
    try:
        return load_json(path)
    except (OSError, ValueError):
        return {}


def write_atomic(path, text):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    os.replace(tmp, path)


def detect_indent(path):
    """Sangría del archivo existente (para no reformatearlo): None si está en una línea."""
    try:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    except OSError:
        return 2
    m = re.search(r"\n([ \t]+)\S", text)
    if not m:
        return None if text.strip() else 2
    ws = m.group(1)
    return "\t" if ws.startswith("\t") else len(ws)


def dump_like(path, data):
    indent = detect_indent(path)
    if indent is None:
        return json.dumps(data, ensure_ascii=False, separators=(",", ":")) + "\n"
    return json.dumps(data, indent=indent, ensure_ascii=False) + "\n"


def norm_path(p):
    return os.path.normcase(os.path.normpath(p)).replace("\\", "/").rstrip("/")


# ----------------------------------------------------------------------------- plugins / MCP / hooks
def cmd_plugin_enabled(name, *files):
    hits = []
    for f in files:
        d = load_json_lenient(f)
        if not isinstance(d, dict):
            continue
        enabled = d.get("enabledPlugins")
        if isinstance(enabled, dict):
            hits += [f"{f}: enabledPlugins.{k}" for k, v in enabled.items() if k.split("@")[0] == name and v]
        installed = d.get("plugins")
        if isinstance(installed, dict):
            hits += [f"{f}: plugins.{k}" for k in installed if k.split("@")[0] == name]
    if hits:
        print("\n".join(hits))
        return 0
    return 1


def _cmdline(entry):
    return " ".join([str(entry.get("command", ""))] + [str(a) for a in entry.get("args", [])])


def cmd_mcp_entry(project_mcp, claude_json, project, name):
    d = load_json_lenient(project_mcp)
    servers = d.get("mcpServers") if isinstance(d, dict) else None
    if isinstance(servers, dict) and name in servers:
        print("project\t" + _cmdline(servers[name]))
        return 0
    c = load_json_lenient(claude_json)
    for key, val in (c.get("projects") or {}).items():
        if norm_path(key) == norm_path(project) and isinstance(val, dict):
            if name in (val.get("mcpServers") or {}):
                print("local\t" + _cmdline(val["mcpServers"][name]))
                return 0
    if name in (c.get("mcpServers") or {}):
        print("user\t" + _cmdline(c["mcpServers"][name]))
        return 0
    return 1


def cmd_mcp_add(project_mcp, name, command, *args):
    d = load_json(project_mcp)  # JSON inválido → excepción: no se escribe nada
    if not isinstance(d, dict):
        raise SystemExit(f"{project_mcp}: la raíz no es un objeto JSON")
    servers = d.setdefault("mcpServers", {})
    if name in servers:
        print(f"ya existe mcpServers.{name}: no se modifica")
        return 0
    servers[name] = {"type": "stdio", "command": command, "args": list(args)}
    write_atomic(project_mcp, dump_like(project_mcp, d))
    print(f"añadido mcpServers.{name}")
    return 0


def cmd_mcp_remove(project_mcp, name, command, *args):
    d = load_json(project_mcp)
    servers = d.get("mcpServers") if isinstance(d, dict) else None
    if not isinstance(servers, dict) or name not in servers:
        print(f"no hay mcpServers.{name}: nada que quitar")
        return 0
    expected = " ".join([command] + list(args))
    if _cmdline(servers[name]) != expected:
        print(f"mcpServers.{name} fue modificado después de instalarlo: no se toca")
        return 1
    del servers[name]
    if not servers:
        del d["mcpServers"]
    if not d:
        os.remove(project_mcp)
        print(f"quitado mcpServers.{name}; {project_mcp} quedó vacío y se borró")
        return 0
    write_atomic(project_mcp, dump_like(project_mcp, d))
    print(f"quitado mcpServers.{name}")
    return 0


# ----------------------------------------------------------------------------- OpenCode (opencode.json)
# Formato verificado el 2026-11-26 en la documentación de OpenCode y de Context7:
#   OpenCode 1.x: mcp.<nombre> = {"type": "local", "command": [...], "enabled": true}
#   OpenCode 2.x: mcp.servers.<nombre> = {"type": "local", "command": [...]}   (sin "enabled")
# Solo se trabaja con JSON estricto: un opencode.json con comentarios (JSONC) da error y no se toca.
OC_SCHEMA = "https://opencode.ai/config.json"


def _oc_servers(d, major, create=False):
    mcp = d.get("mcp")
    if mcp is None:
        if not create:
            return None
        mcp = d["mcp"] = {}
    if not isinstance(mcp, dict):
        raise SystemExit("la clave mcp de opencode.json no es un objeto")
    if int(major) >= 2:
        servers = mcp.get("servers")
        if servers is None and create:
            servers = mcp["servers"] = {}
        return servers if isinstance(servers, dict) else None
    return mcp


def cmd_oc_mcp_entry(path, name):
    """Imprime la línea de comando de la entrada <nombre> (en cualquiera de los dos formatos)."""
    if not os.path.isfile(path):
        return 1
    d = load_json(path)  # JSONC o JSON inválido → error 2: el script lo trata como conflicto
    mcp = d.get("mcp") if isinstance(d, dict) else None
    if not isinstance(mcp, dict):
        return 1
    for container in (mcp.get("servers"), mcp):
        if isinstance(container, dict) and isinstance(container.get(name), dict):
            print(" ".join(str(x) for x in container[name].get("command", [])))
            return 0
    return 1


def cmd_oc_mcp_add(path, major, name, *command):
    d = load_json(path)
    if not isinstance(d, dict):
        raise SystemExit(f"{path}: la raíz no es un objeto JSON")
    created = not d
    if created:
        d["$schema"] = OC_SCHEMA
    servers = _oc_servers(d, major, create=True)
    if servers is None:
        raise SystemExit(f"{path}: no se reconoce la sección de servidores MCP")
    if name in servers:
        print(f"ya existe la entrada {name}: no se modifica")
        return 0
    entry = {"type": "local", "command": list(command)}
    if int(major) < 2:
        entry["enabled"] = True
    servers[name] = entry
    write_atomic(path, dump_like(path, d) if not created else json.dumps(d, indent=2, ensure_ascii=False) + "\n")
    print(f"añadida la entrada {name} (formato de OpenCode {major}.x)")
    return 0


def cmd_oc_mcp_remove(path, name, *command):
    if not os.path.isfile(path):
        print("no existe el archivo: nada que quitar")
        return 0
    d = load_json(path)
    mcp = d.get("mcp") if isinstance(d, dict) else None
    if not isinstance(mcp, dict):
        print(f"no hay entrada {name}: nada que quitar")
        return 0
    for container, parent, key in ((mcp.get("servers"), mcp, "servers"), (mcp, d, "mcp")):
        if isinstance(container, dict) and isinstance(container.get(name), dict):
            if [str(x) for x in container[name].get("command", [])] != list(command):
                print(f"la entrada {name} fue modificada después de instalarla: no se toca")
                return 1
            del container[name]
            if not container:
                del parent[key]
            if isinstance(d.get("mcp"), dict) and not d["mcp"]:
                del d["mcp"]
            if set(d) <= {"$schema"}:
                os.remove(path)
                print(f"quitada la entrada {name}; {path} quedó vacío y se borró")
                return 0
            write_atomic(path, dump_like(path, d))
            print(f"quitada la entrada {name}")
            return 0
    print(f"no hay entrada {name}: nada que quitar")
    return 0


def cmd_hook_has(settings, event, needle):
    d = load_json_lenient(settings)
    for group in ((d.get("hooks") or {}).get(event) or []):
        for hook in (group.get("hooks") or []):
            if needle.lower() in str(hook.get("command", "")).lower():
                return 0
    return 1


def cmd_env_has(settings, var, needle):
    d = load_json_lenient(settings)
    return 0 if needle in str((d.get("env") or {}).get(var, "")) else 1


# ----------------------------------------------------------------------------- TOML
def _array_end(text, i):
    """i apunta a '['; devuelve el índice tras su ']' de cierre (respeta comillas, comentarios, anidamiento)."""
    depth, quote = 0, None
    while i < len(text):
        ch = text[i]
        if quote:
            if quote == '"' and ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
        elif ch in ('"', "'"):
            quote = ch
        elif ch == "#":
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        elif ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise SystemExit("lista TOML sin cerrar")


def _toml_str(s):
    if "'" not in s and "\n" not in s:
        return "'" + s + "'"  # literal: sin escapes, ideal para regex
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def cmd_toml_list(mode, path, table, key, *values):
    try:
        import tomllib
    except ImportError:
        print("Python >= 3.11 requerido (tomllib)")
        return 3
    if mode not in ("check", "apply", "remove"):
        raise SystemExit("modo inválido: " + mode)
    text = ""
    if os.path.isfile(path):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
    current = (tomllib.loads(text).get(table) or {}).get(key) or []
    missing = [v for v in values if v not in current]
    if mode == "check":
        return 0 if not missing else 1
    if mode == "apply":
        if not missing:
            print("valores ya presentes")
            return 0
        new_list = list(current) + missing
    else:
        if not any(v in current for v in values):
            print("valores ya ausentes")
            return 0
        new_list = [c for c in current if c not in values]
    line = f"{key} = [" + ", ".join(_toml_str(v) for v in new_list) + "]"
    header = re.search(r"(?m)^[ \t]*\[" + re.escape(table) + r"\][ \t]*(#.*)?$", text)
    if header:
        nxt = re.search(r"(?m)^[ \t]*\[", text[header.end():])
        end = header.end() + (nxt.start() if nxt else len(text) - header.end())
        assign = re.compile(r"(?m)^[ \t]*" + re.escape(key) + r"[ \t]*=[ \t]*").search(text, header.end(), end)
        if assign:
            new = text[:assign.start()] + line + text[_array_end(text, assign.end()):]
        else:
            new = text[:header.end()] + "\n" + line + text[header.end():]
    else:
        sep = "" if (not text or text.endswith("\n")) else "\n"
        new = text + sep + ("\n" if text else "") + f"[{table}]\n{line}\n"
    # Validación: el resultado parsea, solo cambió esa lista y contiene exactamente lo esperado.
    before, after = tomllib.loads(text), tomllib.loads(new)
    if ((after.get(table) or {}).get(key) or []) != new_list:
        raise SystemExit("fusión TOML inesperada: no se escribe")
    for t, v in before.items():
        if t != table and after.get(t) != v:
            raise SystemExit(f"la fusión alteraría la tabla [{t}]: no se escribe")
    for k, v in (before.get(table) or {}).items():
        if k != key and (after.get(table) or {}).get(k) != v:
            raise SystemExit(f"la fusión alteraría {table}.{k}: no se escribe")
    write_atomic(path, new)
    print(("añadidos: " + ", ".join(missing)) if mode == "apply" else "quitados los valores de SFP")
    return 0


# ----------------------------------------------------------------------------- bloques de texto
def cmd_block_has(path, start):
    if not os.path.isfile(path):
        return 1
    with open(path, encoding="utf-8") as fh:
        return 0 if start in fh.read() else 1


def cmd_block_remove(path, start, end):
    if not os.path.isfile(path):
        print("no existe: nada que quitar")
        return 0
    with open(path, encoding="utf-8", newline="") as fh:
        text = fh.read()
    a = text.find(start)
    if a < 0:
        print("sin bloque: nada que quitar")
        return 0
    b = text.find(end, a)
    if b < 0:
        print("bloque sin marca de cierre: no se toca")
        return 1
    b += len(end)
    while b < len(text) and text[b] in "\r\n":
        b += 1
    new = text[:a] + text[b:]
    if not new.strip():
        os.remove(path)
        print(f"bloque quitado; {path} quedó vacío y se borró")
        return 0
    write_atomic(path, new)
    print("bloque quitado")
    return 0


# ----------------------------------------------------------------------------- estado de integrations.sh
STATE_TOOL = "spec-first-protocol/integrations.sh"


def _load_state(path):
    d = load_json(path) if os.path.isfile(path) else {}
    if d and d.get("tool") != STATE_TOOL:
        raise SystemExit(f"{path} no es un estado de {STATE_TOOL}")
    d.setdefault("tool", STATE_TOOL)
    d.setdefault("records", [])
    return d


def cmd_state_select(path):
    if not os.path.isfile(path):
        return 1
    sel = _load_state(path).get("selection") or {}
    defaults = {"agent": "claude-code", "runner": "auto"}
    for k in ("only", "skip", "scope", "rtk_scope", "agent", "runner"):
        v = str(sel.get(k, defaults.get(k, "")))
        if not re.fullmatch(r"[a-z0-9,-]*", v):
            raise SystemExit(f"valor inválido en selection.{k}: {v!r}")
        print(f"{k}={v}")
    print("force_frontend=" + ("1" if sel.get("force_frontend") else "0"))
    # Un estado sin "agent" es anterior a 1.15.0: los componentes nuevos no estaban en su selección
    print("legacy=" + ("0" if "agent" in sel else "1"))
    return 0


def cmd_state_save(path, only, skip, scope, rtk_scope, force, version, agent="claude-code", runner="auto"):
    d = _load_state(path)
    d["skill_version"] = version
    d["selection"] = {"only": only, "skip": skip, "scope": scope, "rtk_scope": rtk_scope,
                      "force_frontend": force == "1", "agent": agent, "runner": runner}
    d["updated"] = datetime.date.today().isoformat()
    write_atomic(path, json.dumps(d, indent=2, ensure_ascii=False) + "\n")
    return 0


def cmd_state_add(path, component, scope, kind, auto, target, undo):
    d = _load_state(path)
    for r in d["records"]:
        if (r.get("component"), r.get("kind"), r.get("target")) == (component, kind, target):
            return 0
    d["records"].append({"component": component, "scope": scope, "kind": kind, "auto": auto == "1",
                         "target": target, "undo": undo, "date": datetime.date.today().isoformat()})
    write_atomic(path, json.dumps(d, indent=2, ensure_ascii=False) + "\n")
    return 0


def cmd_state_list(path):
    if not os.path.isfile(path):
        return 1
    for i, r in enumerate(_load_state(path)["records"]):
        fields = [str(i), r.get("component", ""), r.get("scope", ""), r.get("kind", ""),
                  "1" if r.get("auto") else "0", r.get("target", ""), r.get("undo", "")]
        print("\t".join(f.replace("\t", " ").replace("\n", " ") for f in fields))
    return 0


def cmd_state_drop(path, *idxs):
    d = _load_state(path)
    drop = {int(i) for i in idxs}
    d["records"] = [r for i, r in enumerate(d["records"]) if i not in drop]
    if not d["records"]:
        os.remove(path)
        print(f"sin registros pendientes: {path} borrado")
        return 0
    write_atomic(path, json.dumps(d, indent=2, ensure_ascii=False) + "\n")
    return 0


def cmd_lock_empty(path):
    """¿skills-lock.json existe y no registra ninguna skill? (lo deja así el CLI de skills al retirar)"""
    d = load_json_lenient(path)
    return 0 if os.path.isfile(path) and isinstance(d, dict) and not d.get("skills") else 1


COMMANDS = {
    "lock-empty": (cmd_lock_empty, 1),
    "plugin-enabled": (cmd_plugin_enabled, 1),
    "mcp-entry": (cmd_mcp_entry, 4),
    "mcp-add": (cmd_mcp_add, 3),
    "mcp-remove": (cmd_mcp_remove, 3),
    "oc-mcp-entry": (cmd_oc_mcp_entry, 2),
    "oc-mcp-add": (cmd_oc_mcp_add, 4),
    "oc-mcp-remove": (cmd_oc_mcp_remove, 3),
    "hook-has": (cmd_hook_has, 3),
    "env-has": (cmd_env_has, 3),
    "toml-list": (cmd_toml_list, 5),
    "block-has": (cmd_block_has, 2),
    "block-remove": (cmd_block_remove, 3),
    "state-select": (cmd_state_select, 1),
    "state-save": (cmd_state_save, 7),
    "state-add": (cmd_state_add, 7),
    "state-list": (cmd_state_list, 1),
    "state-drop": (cmd_state_drop, 1),
}


def main(argv):
    for stream in (sys.stdout, sys.stderr):  # consola de Windows: evitar "est�ndar"
        try:
            stream.reconfigure(encoding="utf-8")
        except (AttributeError, ValueError):
            pass
    if len(argv) < 2 or argv[1] not in COMMANDS:
        print(__doc__, file=sys.stderr)
        return 2
    fn, min_args = COMMANDS[argv[1]]
    if len(argv) - 2 < min_args:
        print(f"{argv[1]}: faltan argumentos", file=sys.stderr)
        return 2
    try:
        return fn(*argv[2:])
    except ValueError as exc:  # JSON/TOML inválido
        print(f"datos inválidos: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
