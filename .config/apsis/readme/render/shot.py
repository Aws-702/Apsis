#!/usr/bin/env python3
# Renders one scene of the real shell offscreen, with stand-in Quickshell modules and demo data, and saves a PNG.
# Edit: demo outputs in demo.json, scenes in scenes/, stand-ins in mocks/, settings, widgets, dock, wallpapers and cover art in demo/; render.sh runs every shot.
import json
import os
import re
import shutil
import subprocess
import sys

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "rhi")
os.environ.setdefault("QSG_RHI_BACKEND", "opengl")
os.environ.setdefault("LIBGL_ALWAYS_SOFTWARE", "1")

from PySide6.QtCore import QObject, Property, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QFontDatabase, QGuiApplication
from PySide6.QtQml import QmlElement, QmlSingleton
from PySide6.QtQuick import QQuickItem, QQuickView

LAB = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.abspath(sys.argv[1])
SCENE = sys.argv[2]
OUT = os.path.abspath(sys.argv[3])
WAIT = int(sys.argv[4]) if len(sys.argv) > 4 else 4500
PALETTE = os.environ.get("SHOT_PALETTE", "cherry")
WORK = os.environ.get("SHOT_WORK") or os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "apsis-render")
HOME = os.path.join(WORK, "home")
QS = os.path.join(WORK, "qs")
ICONS = os.path.join(WORK, "icons")

QML_IMPORT_NAME = "ShotLab"
QML_IMPORT_MAJOR_VERSION = 1

DATA = json.loads(open(os.path.join(LAB, "demo.json")).read().replace("$HOME", HOME))


ICON = ('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">'
        '<rect x="8" y="8" width="112" height="112" rx="28" fill="%s"/>'
        '<text x="64" y="84" font-family="JetBrainsMono Nerd Font, sans-serif" font-size="56" font-weight="800" '
        'text-anchor="middle" fill="#ffffff">%s</text></svg>')


def fresh(path):
    if os.path.isdir(path):
        shutil.rmtree(path)


def prepare():
    os.makedirs(WORK, exist_ok=True)
    for d in (QS, HOME, ICONS, os.path.join(WORK, "scenes")):
        fresh(d)
    shutil.copytree(SRC, QS)
    for root, _, files in os.walk(QS):
        for f in files:
            if not f.endswith(".qml"):
                continue
            p = os.path.join(root, f)
            s = open(p).read()
            s = re.sub(r"^\s*WlrLayershell\.(namespace|keyboardFocus)\s*:.*$\n", "", s, flags=re.M)
            s = s.replace("WlrLayershell.layer:", "layer:")
            open(p, "w").write(s)
    qsb = os.path.join(QS, "shaders/wall.frag.qsb")
    if not os.path.exists(qsb):
        shutil.copy(os.path.join(LAB, "wall.frag.qsb"), qsb)
    shutil.copytree(os.path.join(LAB, "scenes"), os.path.join(WORK, "scenes"))
    demo = os.path.join(LAB, "demo")
    shutil.copytree(os.path.join(demo, "state"), os.path.join(HOME, ".local/state/apsis"))
    shutil.copytree(os.path.join(demo, "wallpapers"), os.path.join(HOME, "Apsis/wallpapers"))
    os.makedirs(os.path.join(HOME, ".cache/apsis"))
    shutil.copy(os.path.join(demo, "cover.jpg"), os.path.join(HOME, ".cache/apsis/cover.jpg"))
    conf = os.path.dirname(SRC)
    if os.path.isdir(os.path.join(conf, "hypr")):
        shutil.copytree(os.path.join(conf, "hypr"), os.path.join(HOME, ".config/hypr"), ignore=shutil.ignore_patterns("*.conf.save", "monitors*"))
    os.makedirs(os.path.join(HOME, ".config/apsis"), exist_ok=True)
    if os.path.exists(os.path.join(conf, "apsis/VERSION")):
        shutil.copy(os.path.join(conf, "apsis/VERSION"), os.path.join(HOME, ".config/apsis/VERSION"))
    os.makedirs(ICONS)
    for a in DATA["apps"]:
        open(os.path.join(ICONS, a["icon"] + ".svg"), "w").write(ICON % (a.get("tile", "#555555"), a["name"][:1].upper()))
    cache = os.path.join(HOME, ".cache/quickshell")
    os.makedirs(cache, exist_ok=True)
    for name, text in (("apsis-mode", "dark"), ("apsis-wall-engine", "apsis"), ("apsis-bar", "show"), ("apsis-palette", PALETTE)):
        open(os.path.join(cache, name), "w").write(text)
    open(os.path.join(cache, "apsis-wallpaper"), "w").write(os.path.join(HOME, "Apsis/wallpapers", os.environ.get("SHOT_WALL", "dusk") + ".jpg"))


@QmlElement
@QmlSingleton
class Shot(QObject):
    rootChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._root = None
        self._z = 0

    def getRoot(self):
        return self._root

    def setRoot(self, r):
        self._root = r
        self.rootChanged.emit()

    root = Property(QQuickItem, getRoot, setRoot, notify=rootChanged)

    @Property("QVariantMap", constant=True)
    def screen(self):
        return {"name": "eDP-1", "width": 1920, "height": 1080, "x": 0, "y": 0, "model": "Display", "devicePixelRatio": 1}

    @Property(str, constant=True)
    def scene(self):
        return QUrl.fromLocalFile(os.path.join(WORK, "scenes", SCENE + ".qml")).toString()

    @Property(str, constant=True)
    def shellDir(self):
        return QS

    @Slot(result=int)
    def nextZ(self):
        self._z += 1
        return self._z

    @Slot(str)
    def log(self, s):
        if os.environ.get("SHOT_LOG"):
            print("[qml]", s)

    @Slot(str, result=str)
    def env(self, name):
        return {"HOME": HOME, "USER": "mira", "XDG_STATE_HOME": "", "XDG_CACHE_HOME": "", "APSIS_ULTRA": ""}.get(name, os.environ.get(name, "") if name not in ("XDG_RUNTIME_DIR",) else os.path.join(HOME, ".run"))

    @Slot(str, str, result=str)
    def iconPath(self, name, fallback):
        p = os.path.join(ICONS, name + ".svg")
        return QUrl.fromLocalFile(p).toString() if os.path.exists(p) else fallback

    @Slot(str, result=bool)
    def exists(self, path):
        return bool(path) and os.path.exists(path)

    @Slot(str, result=str)
    def readFile(self, path):
        try:
            return open(path).read()
        except OSError:
            return ""

    @Slot(str, str)
    def writeFile(self, path, text):
        if path.startswith(HOME):
            os.makedirs(os.path.dirname(path), exist_ok=True)
            open(path, "w").write(text)

    @Slot("QVariant", result=str)
    def output(self, cmd):
        line = " ".join(str(c) for c in (cmd or []))
        for rule in DATA["commands"]:
            if re.search(rule["match"], line, flags=re.S):
                if "run" in rule:
                    env = dict(os.environ, HOME=HOME)
                    return subprocess.run(["sh", "-c", rule["run"]], capture_output=True, text=True, env=env).stdout
                return rule["out"]
        self.log("no demo output for: " + line[:160])
        return ""

    @Slot("QVariant", result=bool)
    def keepsRunning(self, cmd):
        return bool(cmd) and str(cmd[0]) == "cava"

    @Slot(result="QVariantList")
    def apps(self):
        return DATA["apps"]

    @Slot(result="QVariantList")
    def toplevels(self):
        return DATA["toplevels"]

    @Slot(result="QVariantList")
    def btDevices(self):
        return DATA["bluetooth"]

    @Slot(result="QVariantList")
    def pwNodes(self):
        return DATA["pipewire"]

    @Slot("QVariant", result=str)
    def windowShot(self, src):
        return ""


def dump(it, d):
    if d > 12:
        return
    if it.height() < 90 or d < 3:
        print("  " * d + "%s vis=%s x=%.0f y=%.0f w=%.0f h=%.0f" % (it.metaObject().className(), it.isVisible(), it.x(), it.y(), it.width(), it.height()))
    for c in it.childItems():
        dump(c, d + 1)


def main():
    prepare()
    app = QGuiApplication(sys.argv)
    fonts = os.environ.get("SHOT_FONTS", "")
    if fonts and os.path.isdir(fonts):
        for f in os.listdir(fonts):
            QFontDatabase.addApplicationFont(os.path.join(fonts, f))
    view = QQuickView()
    eng = view.engine()
    eng.addImportPath(os.path.join(LAB, "mocks"))
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(1920, 1080)
    view.setSource(QUrl.fromLocalFile(os.path.join(LAB, "base.qml")))
    for e in view.errors():
        print("ERROR", e.toString())
    view.show()

    def grab():
        img = view.grabWindow()
        if os.environ.get("SHOT_DUMP"):
            dump(view.rootObject(), 0)
        img.save(OUT)
        print("saved", OUT, img.width(), img.height())
        app.quit()
    QTimer.singleShot(WAIT, grab)
    app.exec()


if __name__ == "__main__":
    main()
