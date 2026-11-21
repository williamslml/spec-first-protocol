#!/usr/bin/env python3
"""manifest_tool.py — operaciones sobre .sfp/manifest.json que no conviene hacer a mano.

Solo biblioteca estándar de Python 3. Lo invocan verify.sh, fingerprint.sh y uninstall.sh;
también se puede usar directamente.

  check <manifest> [--schema <ruta>]
      Valida contra references/manifest.schema.json y las reglas entre campos que JSON Schema
      no expresa. Salida: líneas "FALLA: ..." / "AVISO: ...". Código 0 sin fallas, 1 con fallas.
  propose <manifest> <huellas.tsv> <salida> [--refresh id,id]
      Escribe en <salida> el manifiesto con actions[].sha256 completado (huellas de fingerprint.sh)
      y, en configure con format json, actions[].changes calculado contra backup.ref. Nunca
      sobrescribe una huella distinta ya registrada salvo los ids de --refresh. No toca <manifest>.
  accept <manifest> <propuesto> <huellas.tsv>
      Reemplaza <manifest> por <propuesto> solo si valida y sus huellas siguen coincidiendo con
      las actuales (nada cambió desde la propuesta). Borra <propuesto>.
  json-diff <antes.json | -> <despues.json>
      Imprime la lista "changes" (formato del esquema) entre dos versiones de un JSON.
  json-plan <manifest> <id> [--apply]
      Retiro de una acción configure con format json: clasifica cada cambio en
      [AUTO]/[MANUAL]/[INFO]/[ERROR]; con --apply revierte solo los [AUTO]. Última línea:
      "RESUMEN auto=N manual=N error=N".
"""
import json
import os
import re
import subprocess
import sys

AREAS = ["identidad", "instalacion", "runtimes", "modelo_agentes", "coordinacion",
         "permisos_aislamiento", "aprobacion_humana", "memoria", "estado_specs",
         "git_concurrencia", "configuracion", "observabilidad", "privacidad_red",
         "limitaciones", "salida"]
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def out(line):
    sys.stdout.write(line + "\n")


def load_json(path):
    with open(path, "rb") as f:
        return json.loads(f.read().decode("utf-8-sig"))


def dump_json(obj, path, indent=2, trailing_nl=True):
    text = json.dumps(obj, indent=indent, ensure_ascii=False)
    if trailing_nl:
        text += "\n"
    tmp = path + ".tmp-manifest-tool"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.replace(tmp, path)


def deq(a, b):
    """Igualdad estricta de tipos (en Python True == 1)."""
    if isinstance(a, bool) or isinstance(b, bool):
        return type(a) is type(b) and a == b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return a == b
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(deq(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(deq(x, y) for x, y in zip(a, b))
    return a == b


# ---------------------------------------------------------------- validación (subconjunto de JSON Schema)
def jtype(v):
    if v is None: return "null"
    if isinstance(v, bool): return "boolean"
    if isinstance(v, int): return "integer"
    if isinstance(v, float): return "number"
    if isinstance(v, str): return "string"
    if isinstance(v, list): return "array"
    if isinstance(v, dict): return "object"
    return "?"


def validate(v, sch, root, path, errs):
    if "$ref" in sch:
        ref = sch["$ref"]
        node = root
        for part in ref.lstrip("#/").split("/"):
            node = node[part]
        return validate(v, node, root, path, errs)
    if "anyOf" in sch:
        if not any(not validate_collect(v, s, root, path) for s in sch["anyOf"]):
            errs.append((path, "no cumple ninguna de las alternativas permitidas"))
        return
    t = sch.get("type")
    if t:
        vt = jtype(v)
        ok = vt == t or (t == "number" and vt == "integer")
        if not ok:
            errs.append((path, "tipo %s, se esperaba %s" % (vt, t)))
            return
    if "const" in sch and not deq(v, sch["const"]):
        errs.append((path, "debe ser %s" % json.dumps(sch["const"], ensure_ascii=False)))
    if "enum" in sch and not any(deq(v, e) for e in sch["enum"]):
        errs.append((path, "valor %s no permitido (permitidos: %s)" % (
            json.dumps(v, ensure_ascii=False), ", ".join(json.dumps(e, ensure_ascii=False) for e in sch["enum"]))))
    if isinstance(v, str):
        if len(v) < sch.get("minLength", 0):
            errs.append((path, "no puede estar vacío"))
        if "pattern" in sch and not re.search(sch["pattern"], v):
            errs.append((path, "formato inválido: %s" % json.dumps(v, ensure_ascii=False)))
    if isinstance(v, (int, float)) and not isinstance(v, bool) and "minimum" in sch and v < sch["minimum"]:
        errs.append((path, "menor que %s" % sch["minimum"]))
    if isinstance(v, dict):
        for k in sch.get("required", []):
            if k not in v:
                errs.append((path, "falta el campo obligatorio '%s'" % k))
        props = sch.get("properties", {})
        addl = sch.get("additionalProperties", True)
        for k, val in v.items():
            if k in props:
                validate(val, props[k], root, path + "." + k, errs)
            elif addl is False:
                errs.append((path, "campo no reconocido '%s' (¿errata?)" % k))
            elif isinstance(addl, dict):
                validate(val, addl, root, path + "." + k, errs)
    if isinstance(v, list):
        if len(v) < sch.get("minItems", 0):
            errs.append((path, "necesita al menos %d elemento(s)" % sch["minItems"]))
        if "items" in sch:
            for i, it in enumerate(v):
                validate(it, sch["items"], root, "%s[%d]" % (path, i), errs)


def validate_collect(v, sch, root, path):
    e = []
    validate(v, sch, root, path, e)
    return e


def unsafe(p):
    return (not isinstance(p, str) or p == "" or p.startswith("/") or "\\" in p
            or re.match(r"^[A-Za-z]:", p) is not None or re.search(r"(^|/)\.\.(/|$)", p) is not None)


def cross_rules(m, root=None):
    """Reglas entre campos. Devuelve (fallas, avisos). root: carpeta del proyecto (para no pedir huella a carpetas)."""
    F, A = [], []
    acts = m.get("actions") if isinstance(m.get("actions"), list) else []
    seen = {}
    for i, a in enumerate(acts):
        if not isinstance(a, dict):
            continue
        p = "$.actions[%d]" % i
        aid, t = a.get("id"), a.get("type")
        if aid in seen and not isinstance(aid, bool):
            F.append("%s: id %s repetido (también en actions[%d])" % (p, aid, seen[aid]))
        seen.setdefault(aid, i)
        if "path" in a and unsafe(a["path"]):
            F.append("%s.path: ruta absoluta o fuera del proyecto: %s" % (p, a["path"]))
        if t == "move" and not a.get("from"):
            F.append("%s: un move necesita 'from' (ruta de origen)" % p)
        if t != "move" and "from" in a:
            F.append("%s: 'from' solo vale en move" % p)
        if t == "merge" and a.get("markers") is not True:
            F.append("%s: un merge debe llevar markers: true" % p)
        if a.get("markers") is True and t not in ("merge", "configure"):
            F.append("%s: markers solo vale en merge o configure" % p)
        if ("format" in a or "changes" in a) and t != "configure":
            F.append("%s: format/changes solo valen en configure" % p)
        if t == "configure" and a.get("format") == "json":
            if a.get("markers") is True:
                F.append("%s: configure json no admite marcadores (JSON no tiene comentarios)" % p)
            if not a.get("changes"):
                A.append("%s: configure json sin 'changes': el retiro será manual. Calcularlos con fingerprint.sh --propose" % p)
        target = os.path.join(root, a["path"]) if root and isinstance(a.get("path"), str) and not unsafe(a["path"]) else None
        no_hash = target is not None and (os.path.isdir(target) or os.path.islink(target))
        if t in ("create", "merge") and not a.get("sha256") and m.get("schema") == 2 and not no_hash:
            A.append("%s: sin sha256 (%s): el retiro no podrá ser automático. Completar con fingerprint.sh --propose" % (p, a.get("path")))
    st = m.get("structure")
    if isinstance(st, dict):
        prof, stage = st.get("profile"), st.get("stage")
        if prof and prof != "ninguno" and not any(deq(stage, s) for s in ("1", "2", 1, 2)):
            F.append("$.structure.stage: debe ser 1 o 2 con el perfil %s" % prof)
        if prof == "ninguno" and any(deq(stage, s) for s in ("1", "2", 1, 2)):
            A.append("$.structure.stage: el perfil ninguno no lleva etapa")
        ws = st.get("workspaces")
        if ws is not None and prof != "monorepo":
            F.append("$.structure.workspaces: solo vale con profile monorepo (hay: %s)" % prof)
        paths = set()
        for i, w in enumerate(ws or []):
            if not isinstance(w, dict):
                continue
            wp = "$.structure.workspaces[%d]" % i
            if w.get("profile") in ("monorepo", "ninguno"):
                F.append("%s.profile: un workspace no puede ser %s" % (wp, w.get("profile")))
            if not any(deq(w.get("stage"), s) for s in ("1", "2", 1, 2)):
                F.append("%s.stage: debe ser 1 o 2" % wp)
            if w.get("path") in paths:
                F.append("%s.path: workspace repetido: %s" % (wp, w.get("path")))
            paths.add(w.get("path"))
    cl = m.get("classification")
    if isinstance(cl, dict):
        orch = cl.get("orchestration")
        var = (m.get("source_methodology") or {}).get("variant")
        if orch == "none" and var == "con-orquestador":
            F.append("$.classification.orchestration es none pero la variante es con-orquestador")
        if orch not in (None, "none") and var == "sin-orquestador":
            F.append("$.classification.orchestration es %s pero la variante es sin-orquestador" % orch)
        if orch not in (None, "none") and "orchestrator_profile" not in cl:
            (F if m.get("schema") == 2 else A).append(
                "$.classification: con orquestador falta orchestrator_profile (ficha de templates.md sección 15)")
        if orch == "none" and "orchestrator_profile" in cl:
            F.append("$.classification.orchestrator_profile: sobra sin orquestador")
        if cl.get("project_state") == "existente" and cl.get("intrusion") == "n/a":
            F.append("$.classification.intrusion: un proyecto existente necesita un nivel de intrusión")
    for i, r in enumerate(((m.get("product") or {}).get("repos")) or []):
        loc = r.get("location", "") if isinstance(r, dict) else ""
        if re.search(r"://[^/]*@", loc or ""):
            F.append("$.product.repos[%d].location: contiene credenciales o usuario en la URL; quitarlos" % i)
    return F, A


def cmd_check(args):
    if not args:
        out("uso: check <manifest> [--schema ruta]"); return 2
    mpath = args[0]
    spath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "references", "manifest.schema.json")
    if "--schema" in args:
        spath = args[args.index("--schema") + 1]
    try:
        m = load_json(mpath)
    except (OSError, ValueError) as e:
        out("FALLA: el manifiesto no es JSON válido: %s" % e); return 1
    schema = load_json(spath)
    errs = []
    validate(m, schema, schema, "$", errs)
    F, A = cross_rules(m, os.path.dirname(os.path.dirname(os.path.abspath(mpath))))
    legacy = m.get("schema") == 1 if isinstance(m, dict) else False
    critical = re.compile(r"repetido|fuera del proyecto|credenciales")
    for p, msg in errs:
        line = "%s: %s" % (p, msg)
        if legacy:
            A.append(line + " (schema 1: informativo; el modo Actualización propone migrar a schema 2)")
        else:
            F.append(line)
    if legacy:
        keep = [f for f in F if critical.search(f)]
        A.extend(f + " (schema 1: informativo)" for f in F if not critical.search(f))
        F = keep
    for f in F:
        out("FALLA: " + f)
    for a in A:
        out("AVISO: " + a)
    if not F and not A:
        out("ok: el manifiesto cumple el esquema (schema %s)" % m.get("schema"))
    return 1 if F else 0


# ---------------------------------------------------------------- huellas
def read_tsv(path):
    res = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            parts = line.rstrip("\r\n").split("\t")
            if len(parts) >= 4:
                res[parts[0]] = parts[3]
    return res


def git_show(ref, path, cwd):
    try:
        r = subprocess.run(["git", "show", "%s:%s" % (ref, path)], cwd=cwd,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except OSError:
        return None, "git no disponible"
    if r.returncode != 0:
        err = r.stderr.decode("utf-8", "replace")
        if "does not exist" in err or "exists on disk, but not in" in err:
            return {}, None
        return None, "no se pudo leer %s en %s" % (path, ref)
    try:
        return json.loads(r.stdout.decode("utf-8-sig")), None
    except ValueError:
        return None, "la versión de %s en %s no es JSON estricto" % (path, ref)


def cmd_propose(args):
    if len(args) < 3:
        out("uso: propose <manifest> <huellas.tsv> <salida> [--refresh id,id]"); return 2
    mpath, tsv, dest = args[:3]
    refresh = set()
    if "--refresh" in args:
        refresh = set(x.strip() for x in args[args.index("--refresh") + 1].split(",") if x.strip())
    m = load_json(mpath)
    root = os.path.dirname(os.path.dirname(os.path.abspath(mpath)))
    hashes = read_tsv(tsv)
    ref = ((m.get("backup") or {}).get("ref")) or "pre-sfp"
    problems = 0
    for a in m.get("actions") or []:
        aid, t, p = str(a.get("id")), a.get("type"), a.get("path")
        if t == "configure" and a.get("format") == "json":
            if a.get("changes") and aid not in refresh:
                out("  id=%s %s: changes ya registrados (%d)" % (aid, p, len(a["changes"])))
                continue
            if unsafe(p) or not os.path.isfile(os.path.join(root, p)):
                out("  id=%s %s: no existe; no se calculan changes" % (aid, p)); problems += 1; continue
            before, err = git_show(ref, p, root)
            if err:
                out("  id=%s %s: %s; registrar changes con 'manifest_tool.py json-diff <copia-previa> %s'" % (aid, p, err, p))
                problems += 1; continue
            try:
                after = load_json(os.path.join(root, p))
            except ValueError:
                out("  id=%s %s: no es JSON estricto (¿comentarios?): el retiro será manual" % (aid, p)); problems += 1; continue
            a["changes"] = json_diff(before, after)
            out("  id=%s %s: changes calculados contra %s (%d cambio(s))" % (aid, p, ref, len(a["changes"])))
            continue
        if t not in ("create", "merge", "configure"):
            continue
        h = hashes.get(aid, "")
        if not HEX64.match(h):
            if h != "-":
                out("  id=%s %s: sin huella medible (%s)" % (aid, p, h or "no aparece en la medición")); problems += 1
            continue
        cur = a.get("sha256", "")
        if not cur:
            a["sha256"] = h
            out("  id=%s %s: huella añadida" % (aid, p))
        elif cur == h:
            out("  id=%s %s: huella ya correcta" % (aid, p))
        elif aid in refresh:
            a["sha256"] = h
            out("  id=%s %s: huella ACTUALIZADA (--refresh: el usuario confirmó que el contenido actual es el del setup)" % (aid, p))
        else:
            out("  id=%s %s: la huella registrada DIFIERE de la actual: se mantiene la registrada (¿editado después del setup?). Solo con confirmación del usuario: --refresh %s" % (aid, p, aid))
    dump_json(m, dest)
    out("propuesta escrita en %s (el manifiesto no se modificó). Revisarla con el usuario y aceptarla con fingerprint.sh --accept" % dest)
    return 1 if problems else 0


def cmd_accept(args):
    if len(args) < 3:
        out("uso: accept <manifest> <propuesto> <huellas.tsv>"); return 2
    mpath, ppath, tsv = args[:3]
    if not os.path.isfile(ppath):
        out("FALLA: no hay propuesta (%s); ejecutar antes fingerprint.sh --propose" % ppath); return 1
    rc = cmd_check([ppath])
    if rc != 0:
        out("FALLA: la propuesta no valida; no se aplica"); return 1
    prop = load_json(ppath)
    hashes = read_tsv(tsv)
    stale = []
    for a in prop.get("actions") or []:
        h = a.get("sha256")
        if h and HEX64.match(h) and hashes.get(str(a.get("id"))) != h:
            stale.append("id=%s %s" % (a.get("id"), a.get("path")))
    if stale:
        out("FALLA: el proyecto cambió desde la propuesta (%s); repetir fingerprint.sh --propose" % ", ".join(stale))
        return 1
    os.replace(ppath, mpath)
    out("aceptada: %s actualizado con la propuesta" % mpath)
    return 0


# ---------------------------------------------------------------- JSON: diff y retiro
def ptr_join(base, key):
    return base + "/" + str(key).replace("~", "~0").replace("/", "~1")


def ptr_parts(ptr):
    if ptr == "":
        return []
    return [p.replace("~1", "/").replace("~0", "~") for p in ptr[1:].split("/")]


MISSING = object()


def ptr_get(doc, ptr):
    cur = doc
    for part in ptr_parts(ptr):
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        elif isinstance(cur, list) and part.isdigit() and int(part) < len(cur):
            cur = cur[int(part)]
        else:
            return MISSING
    return cur


def ptr_set(doc, ptr, value):
    parts = ptr_parts(ptr)
    cur = doc
    for part in parts[:-1]:
        if part not in cur:
            cur[part] = {}
        cur = cur[part]
    cur[parts[-1]] = value


def ptr_del(doc, ptr):
    parts = ptr_parts(ptr)
    cur = doc
    for part in parts[:-1]:
        cur = cur[part]
    del cur[parts[-1]]


def json_diff(before, after, ptr=""):
    ch = []
    if isinstance(before, dict) and isinstance(after, dict):
        for k in after:
            if k not in before:
                ch.append({"pointer": ptr_join(ptr, k), "op": "add", "after": after[k]})
            else:
                ch.extend(json_diff(before[k], after[k], ptr_join(ptr, k)))
        for k in before:
            if k not in after:
                ch.append({"pointer": ptr_join(ptr, k), "op": "remove", "before": before[k]})
    elif isinstance(before, list) and isinstance(after, list):
        rest = list(after)
        removed = False
        for it in before:
            idx = next((i for i, x in enumerate(rest) if deq(x, it)), None)
            if idx is None:
                removed = True
                break
            rest.pop(idx)
        if removed:
            ch.append({"pointer": ptr, "op": "replace", "before": before, "after": after})
        elif rest:
            ch.append({"pointer": ptr, "op": "append", "items": rest})
    elif not deq(before, after):
        ch.append({"pointer": ptr, "op": "replace", "before": before, "after": after})
    return ch


def cmd_json_diff(args):
    if len(args) < 2:
        out("uso: json-diff <antes.json | -> <despues.json>"); return 2
    before = {} if args[0] == "-" else load_json(args[0])
    sys.stdout.write(json.dumps(json_diff(before, load_json(args[1])), indent=2, ensure_ascii=False) + "\n")
    return 0


def detect_indent(text):
    for line in text.splitlines()[1:]:
        s = line[:len(line) - len(line.lstrip())]
        if s:
            return "\t" if s.startswith("\t") else len(s)
    return 2


def cmd_json_plan(args):
    if len(args) < 2:
        out("uso: json-plan <manifest> <id> [--apply]"); return 2
    mpath, aid = args[0], args[1]
    apply = "--apply" in args
    m = load_json(mpath)
    root = os.path.dirname(os.path.dirname(os.path.abspath(mpath)))
    act = next((a for a in m.get("actions") or [] if str(a.get("id")) == aid), None)
    n = {"auto": 0, "manual": 0, "error": 0}

    def say(kind, msg):
        if kind in n:
            n[kind] += 1
        out("[%s]%sid=%s %s" % (kind.upper(), " " * (7 - len(kind)), aid, msg))

    def done():
        out("RESUMEN auto=%d manual=%d error=%d" % (n["auto"], n["manual"], n["error"]))
        return 1 if n["error"] else (3 if n["manual"] else 0)

    if act is None:
        say("error", "no existe en el manifiesto"); return done()
    p = act.get("path", "")
    if unsafe(p):
        say("error", "ruta inválida o fuera del proyecto: %s" % p); return done()
    full = os.path.join(root, p)
    changes = act.get("changes") or []
    if not changes:
        say("manual", "%s: configure json sin 'changes' registrados: revertir a mano (ver note y el respaldo)" % p); return done()
    if not os.path.isfile(full):
        say("info", "%s ya no existe" % p); return done()
    with open(full, "rb") as f:
        raw = f.read().decode("utf-8-sig")
    try:
        doc = json.loads(raw)
    except ValueError:
        say("manual", "%s no es JSON estricto (¿comentarios?): revertir a mano los %d cambio(s) registrados" % (p, len(changes))); return done()
    ops = []
    for c in reversed(changes):
        ptr, op = c.get("pointer", ""), c.get("op")
        cur = ptr_get(doc, ptr)
        label = "%s %s" % (p, ptr or "(raíz)")
        if ptr == "" and op != "append":
            say("manual", "%s: el setup reemplazó el documento entero: restaurarlo desde el respaldo" % label)
            continue
        if op == "add":
            if cur is MISSING:
                say("info", "%s: la clave añadida ya no está" % label)
            elif deq(cur, c.get("after")):
                say("auto", "%s: QUITAR clave añadida por el setup" % label); ops.append(("del", ptr, None, label))
            else:
                say("manual", "%s: la clave añadida fue EDITADA después del setup: se conserva" % label)
        elif op == "replace":
            if cur is not MISSING and deq(cur, c.get("after")):
                say("auto", "%s: RESTAURAR el valor previo" % label); ops.append(("set", ptr, c.get("before"), label))
            else:
                say("manual", "%s: el valor cambió después del setup (o ya no está): decidir con el usuario si restaurar %s" % (
                    label, json.dumps(c.get("before"), ensure_ascii=False)))
        elif op == "remove":
            if cur is MISSING:
                say("auto", "%s: VOLVER A PONER la clave que el setup quitó" % label); ops.append(("set", ptr, c.get("before"), label))
            else:
                say("manual", "%s: la clave que el setup quitó ha vuelto a aparecer con otro valor: se conserva" % label)
        elif op == "append":
            if not isinstance(cur, list):
                say("info", "%s: la lista ya no existe" % label)
                continue
            for it in c.get("items") or []:
                if any(deq(x, it) for x in cur):
                    say("auto", "%s: QUITAR elemento añadido %s" % (label, json.dumps(it, ensure_ascii=False)))
                    ops.append(("pull", ptr, it, label))
                else:
                    say("info", "%s: el elemento %s ya no está" % (label, json.dumps(it, ensure_ascii=False)))
        else:
            say("error", "%s: operación desconocida %s" % (label, op))
    if apply and ops:
        for kind, ptr, val, label in ops:
            if kind == "del":
                ptr_del(doc, ptr)
            elif kind == "set":
                ptr_set(doc, ptr, val)
            else:
                lst = ptr_get(doc, ptr)
                for i, x in enumerate(lst):
                    if deq(x, val):
                        del lst[i]
                        break
        dump_json(doc, full, indent=detect_indent(raw), trailing_nl=raw.endswith("\n"))
        out("[HECHO]  id=%s %s: %d cambio(s) revertidos (el formato del JSON se normaliza)" % (aid, p, len(ops)))
    return done()


def main(argv):
    cmds = {"check": cmd_check, "propose": cmd_propose, "accept": cmd_accept,
            "json-diff": cmd_json_diff, "json-plan": cmd_json_plan}
    if len(argv) < 2 or argv[1] not in cmds:
        sys.stdout.write(__doc__)
        return 2
    try:
        sys.stdout.reconfigure(encoding="utf-8", newline="\n")
    except AttributeError:
        pass
    return cmds[argv[1]](argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
