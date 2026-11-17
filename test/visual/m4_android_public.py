"""ADB somente para homologação pública do app normal; sem autenticação/envios."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument("action", choices=["inspect", "tap", "focus-index", "back", "scroll", "capture", "restart", "email"])
parser.add_argument("value", nargs="?")
parser.add_argument("--execute-public", action="store_true")
args = parser.parse_args()
if not args.execute_public:
    print("Desabilitado: exige --execute-public; somente área pública.")
    raise SystemExit(0)

adb_path = Path(os.environ["LOCALAPPDATA"]) / "Android/sdk/platform-tools/adb.exe"
device = "127.0.0.1:5556"
output = Path("build/m4-6-android")
output.mkdir(parents=True, exist_ok=True)

def adb(*command):
    result = subprocess.run([str(adb_path), "-s", device, *command], capture_output=True, timeout=40)
    if result.returncode:
        raise RuntimeError("ADB_OPERATION_FAILED")
    return result.stdout

def nodes():
    adb("shell", "uiautomator", "dump", "/sdcard/bolsozen-m46-public.xml")
    raw = adb("shell", "cat", "/sdcard/bolsozen-m46-public.xml").decode("utf-8")
    tree = ET.fromstring(raw)
    items = list(tree.iter("node"))
    if not any(n.get("package") == "com.bolsozen.bolsozen" for n in items):
        raise RuntimeError("NORMAL_APP_NOT_READY_NO_CAPTURE")
    if any(n.get("text") in {"Perfil", "Sair"} or n.get("content-desc") in {"Perfil", "Sair"} for n in items):
        raise RuntimeError("EXISTING_PRIVATE_SESSION_STOP_NO_REUSE")
    return items

items = nodes() if args.action != "restart" else []
if args.action == "inspect":
    print(json.dumps([{"text": n.get("text"), "label": n.get("content-desc"),
                       "bounds": n.get("bounds"), "focused": n.get("focused"), "class": n.get("class")}
                      for n in items if n.get("text") or n.get("content-desc") or n.get("class") == "android.widget.EditText"]))
elif args.action == "tap":
    allowed = {"Entrar", "Criar conta", "Esqueci minha senha", "Voltar", "Já tenho conta", "E-mail", "Senha", "Nome"}
    if args.value not in allowed:
        raise RuntimeError("PUBLIC_CONTROL_REQUIRED")
    if args.value in {"Entrar", "Criar conta"}:
        welcome = any("Controle suas finanças, alcance" in (n.get("text", "") + n.get("content-desc", "")) for n in items)
        login_to_register = args.value == "Criar conta" and any("Entrar no BolsoZen" in (n.get("text", "") + n.get("content-desc", "")) for n in items)
        if not welcome and not login_to_register:
            raise RuntimeError("SUBMISSION_NOT_ALLOWED")
    found = next(n for n in items if n.get("text") == args.value or n.get("content-desc") == args.value)
    coords = list(map(int, re.findall(r"\d+", found.get("bounds"))))
    adb("shell", "input", "tap", str((coords[0] + coords[2]) // 2), str((coords[1] + coords[3]) // 2))
elif args.action == "back":
    adb("shell", "input", "keyevent", "4")
elif args.action == "focus-index":
    editable = [n for n in items if n.get("class") == "android.widget.EditText"]
    index = int(args.value)
    if index < 0 or index >= len(editable):
        raise RuntimeError("PUBLIC_FIELD_REQUIRED")
    coords = list(map(int, re.findall(r"\d+", editable[index].get("bounds"))))
    adb("shell", "input", "tap", str((coords[0] + coords[2]) // 2), str((coords[1] + coords[3]) // 2))
elif args.action == "scroll":
    adb("shell", "input", "swipe", "1100", "850", "1100", "250", "500")
elif args.action == "capture":
    if not re.fullmatch(r"[a-z0-9-]+", args.value or ""):
        raise RuntimeError("SAFE_CAPTURE_NAME_REQUIRED")
    target = output / (args.value + ".png")
    target.write_bytes(adb("exec-out", "screencap", "-p"))
    print(json.dumps({"captured": str(target)}))
elif args.action == "restart":
    previous = adb("shell", "pidof", "com.bolsozen.bolsozen").decode().strip()
    adb("shell", "am", "force-stop", "com.bolsozen.bolsozen")
    adb("shell", "am", "start", "-n", "com.bolsozen.bolsozen/.MainActivity")
    print(json.dumps({"oldPid": previous, "forceStopped": True, "startedNormalActivity": True}))
elif args.action == "email":
    if not any(n.get("class") == "android.widget.EditText" and n.get("focused") == "true" for n in items):
        raise RuntimeError("FOCUSED_PUBLIC_FIELD_REQUIRED")
    # Endereço ilustrativo, sem conta e sem senha; nunca aciona submit.
    adb("shell", "input", "text", "publico@example.test")
