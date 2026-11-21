#!/usr/bin/env python3
"""Verifica las reglas de formato del proyecto en los textos propios.

Uso:
    python tests/verificar_formato.py                    # revisa los archivos de texto
    python tests/verificar_formato.py --commits ORIGEN..DESTINO   # además, los mensajes de commit

Reglas que comprueba:
  - Sin emojis.
  - Sin el símbolo "§" ni referencias numeradas a secciones.
  - Sin voseo (español neutro). Una línea que contenga la palabra "voseo" se omite,
    porque explica la regla.
  - Sin firmas de asistentes de IA en los mensajes de commit.
  - Los enlaces internos del README (a secciones y a archivos) existen.
  - Las entradas del CHANGELOG tienen la línea "[accion: si/no]" bien formada.

No revisa references/vendor/, que contiene material de terceros.
Solo usa la biblioteca estándar. Código de salida: 0 todo bien, 1 hay problemas.
"""
import argparse
import re
import subprocess
import sys
import unicodedata
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
EXTENSIONES = {".md", ".yml", ".yaml", ".sh", ".py", ".json", ".ps1"}
EXCLUIDAS = {".git", "vendor", "node_modules", "__pycache__"}
ESTE_ARCHIVO = Path(__file__).resolve()

problemas = []


def avisar(archivo, linea, texto):
    ubicacion = f"{archivo}:{linea}" if linea else str(archivo)
    problemas.append(f"{ubicacion}  {texto}")


def es_emoji(c):
    cp = ord(c)
    return (
        0x1F300 <= cp <= 0x1FAFF
        or 0x2600 <= cp <= 0x27BF
        or 0x1F000 <= cp <= 0x1F2FF
        or cp in (0x2B50, 0x2B06, 0x2B07, 0x2B55, 0x2B1B, 0x2B1C, 0x231A, 0x231B, 0x23E9, 0x23EA, 0x23F0, 0x23F3)
    ) and unicodedata.category(c) != "Mn"


# Formas verbales de voseo y pronombres que no existen en español neutro
VOSEO = re.compile(
    r"\b(vos|sos|tenés|querés|podés|sabés|hacés|decís|mirá|fijate|fijáte|andá|ponete|pone[tl]e|"
    r"acordate|tené|hacé|decime|dame|dale|usá|probá|escribí|ejecutá|corré|elegí|revisá|agregá|"
    r"confirmá|subí|pasá|abrí|copiá|creá|guardá|instalá|borrá|completá)\b",
    re.IGNORECASE,
)
# Palabras ambiguas que son correctas en español neutro con otro sentido
VOSEO_AMBIGUAS = {"dame", "dale", "pone"}


def archivos_de_texto():
    for ruta in sorted(RAIZ.rglob("*")):
        if not ruta.is_file() or ruta.suffix.lower() not in EXTENSIONES:
            continue
        partes = set(ruta.relative_to(RAIZ).parts)
        if partes & EXCLUIDAS or ruta.resolve() == ESTE_ARCHIVO:
            continue
        yield ruta


def revisar_texto(ruta):
    rel = ruta.relative_to(RAIZ).as_posix()
    try:
        contenido = ruta.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        avisar(rel, 0, "no está en UTF-8")
        return
    for n, linea in enumerate(contenido.splitlines(), 1):
        if any(es_emoji(c) for c in linea):
            avisar(rel, n, "contiene un emoji")
        if "§" in linea:
            avisar(rel, n, 'contiene "§" (no se usan referencias numeradas a secciones)')
        if "voseo" in linea.lower():
            continue
        for m in VOSEO.finditer(linea):
            if m.group(1).lower() in VOSEO_AMBIGUAS:
                continue
            avisar(rel, n, f'posible voseo: "{m.group(1)}"')


def revisar_enlaces_readme():
    readme = RAIZ / "README.md"
    if not readme.exists():
        avisar("README.md", 0, "no existe")
        return
    texto = readme.read_text(encoding="utf-8")
    sin_codigo = re.sub(r"```.*?```", "", texto, flags=re.S)

    def ancla(titulo):
        t = re.sub(r"[`*_]", "", titulo.strip().lower())
        t = re.sub(r"[^\w\s-]", "", t, flags=re.U)
        return re.sub(r"\s", "-", t)

    anclas = {ancla(m.group(2)) for m in re.finditer(r"^(#{1,6})\s+(.+)$", sin_codigo, flags=re.M)}
    for m in re.finditer(r"\]\(([^)\s]+)\)", sin_codigo):
        destino = m.group(1)
        if destino.startswith(("http://", "https://", "mailto:")):
            continue
        if destino.startswith("#"):
            if destino[1:] not in anclas:
                avisar("README.md", 0, f"el enlace a la sección {destino} no tiene destino")
            continue
        ruta = destino.split("#")[0].split("?")[0]
        if ruta and not (RAIZ / ruta).exists():
            avisar("README.md", 0, f"el enlace a {ruta} apunta a un archivo que no existe")


def revisar_changelog():
    archivo = RAIZ / "CHANGELOG.md"
    if not archivo.exists():
        avisar("CHANGELOG.md", 0, "no existe")
        return
    lineas = archivo.read_text(encoding="utf-8").splitlines()
    versiones = [i for i, l in enumerate(lineas) if re.match(r"^## \d+\.\d+\.\d+", l)]
    if not versiones:
        avisar("CHANGELOG.md", 0, "no tiene ninguna versión con el formato '## X.Y.Z'")
    vistas = set()
    for l in lineas:
        m = re.match(r"^## (\d+\.\d+\.\d+)", l)
        if m:
            if m.group(1) in vistas:
                avisar("CHANGELOG.md", 0, f"la versión {m.group(1)} aparece repetida")
            vistas.add(m.group(1))
    for n, l in enumerate(lineas, 1):
        if "[accion:" in l and not re.search(r"\[accion: (si|no)\]", l):
            avisar("CHANGELOG.md", n, 'la marca debe ser exactamente "[accion: si]" o "[accion: no]"')


def revisar_commits(rango):
    try:
        salida = subprocess.run(
            ["git", "log", "--format=%H%x1f%B%x1e", rango],
            cwd=RAIZ, capture_output=True, text=True, encoding="utf-8", check=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        avisar("git", 0, f"no se pudo leer el rango de commits {rango}: {e}")
        return
    firma = re.compile(
        r"^(co-authored-by:.*(claude|anthropic|copilot|openai|chatgpt|gemini|codex|cursor|devin|aider)"
        r"|.*generated (with|by).*(claude|copilot|chatgpt|gemini|codex|cursor)"
        r"|claude-session:)",
        re.IGNORECASE,
    )
    for bloque in salida.split("\x1e"):
        if not bloque.strip():
            continue
        sha, _, mensaje = bloque.strip().partition("\x1f")
        for l in mensaje.splitlines():
            if firma.match(l.strip()):
                avisar(f"commit {sha[:7]}", 0, f"contiene una firma de asistente de IA: {l.strip()[:70]}")
            if any(es_emoji(c) for c in l):
                avisar(f"commit {sha[:7]}", 0, "el mensaje contiene un emoji")


def main():
    ap = argparse.ArgumentParser(description="Verifica las reglas de formato del proyecto.")
    ap.add_argument("--commits", metavar="RANGO", help="revisar también los mensajes de commit de este rango, por ejemplo origen/master..HEAD")
    args = ap.parse_args()

    total = 0
    for ruta in archivos_de_texto():
        total += 1
        revisar_texto(ruta)
    revisar_enlaces_readme()
    revisar_changelog()
    if args.commits:
        revisar_commits(args.commits)

    if problemas:
        print(f"Se encontraron {len(problemas)} problemas en el formato:\n")
        for p in problemas:
            print("  " + p)
        return 1
    print(f"Formato correcto: {total} archivos revisados, sin problemas.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
