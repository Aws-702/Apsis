#!/usr/bin/env python3
# Tests the Bluetooth pairing agent against a fake BlueZ on a private session bus.
# Run through btagent_test.sh.

import json
import os
import queue
import subprocess
import sys
import threading
import time

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

HERE = os.path.dirname(os.path.abspath(__file__))
HELPER = os.path.join(HERE, "..", "..", "hypr", "scripts", "apsis-bt-agent.py")
LOG = os.environ.get("APSIS_BT_TEST_LOG", "/tmp/apsis-bt-fake.log")
DEV_NEW = "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_01"
DEV_PAIRED = "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_02"

MANAGER_XML = """<node><interface name="org.bluez.AgentManager1">
<method name="RegisterAgent"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
<method name="RequestDefaultAgent"><arg type="o" direction="in"/></method>
<method name="UnregisterAgent"><arg type="o" direction="in"/></method></interface></node>"""
PROPS_XML = """<node><interface name="org.freedesktop.DBus.Properties">
<method name="GetAll"><arg type="s" direction="in"/><arg type="a{sv}" direction="out"/></method>
<method name="Set"><arg type="s" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="in"/></method>
</interface></node>"""

def note(line):
    with open(LOG, "a") as f:
        f.write(line + "\n")

def run_fake():
    conn = Gio.bus_get_sync(Gio.BusType.SESSION, None)

    def manager(c, sender, path, iface, method, params, inv):
        a = params.unpack()
        if method == "RegisterAgent":
            note("register %s %s %s" % (sender, a[0], a[1]))
        elif method == "RequestDefaultAgent":
            note("default " + a[0])
        elif method == "UnregisterAgent":
            note("unregister " + a[0])
        inv.return_value(None)

    def device(paired):
        def handler(c, sender, path, iface, method, params, inv):
            if method == "GetAll":
                props = {"Alias": GLib.Variant("s", "Test Phone" if not paired else "Old Phone"),
                         "Address": GLib.Variant("s", path.rsplit("dev_", 1)[1].replace("_", ":")),
                         "Paired": GLib.Variant("b", paired)}
                inv.return_value(GLib.Variant("(a{sv})", (props,)))
            else:
                a = params.unpack()
                note("set %s %s %s" % (path, a[1], a[2]))
                inv.return_value(None)
        return handler

    conn.register_object("/org/bluez", Gio.DBusNodeInfo.new_for_xml(MANAGER_XML).interfaces[0], manager, None, None)
    for path, paired in ((DEV_NEW, False), (DEV_PAIRED, True)):
        conn.register_object(path, Gio.DBusNodeInfo.new_for_xml(PROPS_XML).interfaces[0], device(paired), None, None)
    Gio.bus_own_name_on_connection(conn, "org.bluez", Gio.BusNameOwnerFlags.NONE, None, None)
    GLib.MainLoop().run()

passed = failed = 0

def check(name, got, want=True):
    global passed, failed
    if got == want:
        passed += 1
    else:
        failed += 1
        print("FAIL %s: expected %r, got %r" % (name, want, got))

class Helper:
    def __init__(self, timeout="60", any_sender=True):
        env = dict(os.environ, APSIS_BT_BUS="session", APSIS_BT_TIMEOUT=timeout)
        if any_sender:
            env["APSIS_BT_ANY_SENDER"] = "1"
        self.p = subprocess.Popen([sys.executable, HELPER], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  text=True, env=env)
        self.events = queue.Queue()
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        for line in self.p.stdout:
            self.events.put(json.loads(line))

    def event(self, timeout=5):
        try:
            return self.events.get(timeout=timeout)
        except queue.Empty:
            return None

    def answer(self, rid, accept, value=None):
        msg = {"id": rid, "accept": accept}
        if value is not None:
            msg["value"] = value
        self.p.stdin.write(json.dumps(msg) + "\n")
        self.p.stdin.flush()

def agent_call(conn, sender, method, args, sig, out=None):
    res = {}

    def go():
        try:
            r = conn.call_sync(sender, "/org/apsis/BtAgent", "org.bluez.Agent1", method,
                               GLib.Variant(sig, args), GLib.VariantType(out) if out else None,
                               Gio.DBusCallFlags.NONE, 15000, None)
            res["ok"] = r.unpack() if r is not None else None
        except GLib.Error as e:
            res["err"] = Gio.DBusError.get_remote_error(e)
    t = threading.Thread(target=go)
    t.start()
    return t, res

def strict_sender(helper):
    lines = [l for l in open(LOG).read().splitlines() if l.startswith("register ")]
    return lines[-1].split()[1]

def wait_log(prefix, timeout=5):
    end = time.time() + timeout
    while time.time() < end:
        if os.path.exists(LOG):
            for line in open(LOG).read().splitlines():
                if line.startswith(prefix):
                    return line
        time.sleep(0.05)
    return None

def main():
    open(LOG, "w").close()
    fake = subprocess.Popen([sys.executable, __file__, "fake"])
    conn = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    time.sleep(0.8)

    h = Helper(timeout="2")
    check("registers", (h.event() or {}).get("event"), "registered")
    reg = wait_log("register ")
    sender = reg.split()[1]
    check("capability is DisplayYesNo", reg.split()[3], "DisplayYesNo")
    check("asks to be the default agent", wait_log("default ") is not None)

    t, r = agent_call(conn, sender, "RequestConfirmation", (DEV_NEW, 4242), "(ou)")
    ev = h.event()
    check("confirm: request event", (ev["event"], ev["kind"], ev["code"], ev["name"]), ("request", "confirm", "004242", "Test Phone"))
    h.answer(ev["id"], True)
    t.join()
    check("confirm accepted returns", r, {"ok": ()})
    check("confirm accepted trusts the device", wait_log("set " + DEV_NEW + " Trusted True") is not None)

    t, r = agent_call(conn, sender, "RequestConfirmation", (DEV_NEW, 1), "(ou)")
    ev = h.event()
    h.answer(ev["id"], False)
    t.join()
    check("confirm rejected is Rejected", r, {"err": "org.bluez.Error.Rejected"})

    t, r = agent_call(conn, sender, "RequestPinCode", (DEV_NEW,), "(o)", "(s)")
    ev = h.event()
    check("pin: kind", ev["kind"], "pin")
    h.answer(ev["id"], True, "0000")
    t.join()
    check("pin returned", r, {"ok": ("0000",)})

    t, r = agent_call(conn, sender, "RequestPasskey", (DEV_NEW,), "(o)", "(u)")
    ev = h.event()
    h.answer(ev["id"], True, "4242")
    t.join()
    check("passkey returned", r, {"ok": (4242,)})
    t, r = agent_call(conn, sender, "RequestPasskey", (DEV_NEW,), "(o)", "(u)")
    ev = h.event()
    h.answer(ev["id"], True, "abc")
    t.join()
    check("a bad passkey is rejected", r, {"err": "org.bluez.Error.Rejected"})

    t, r = agent_call(conn, sender, "AuthorizeService", (DEV_PAIRED, "0000110b-0000-1000-8000-00805f9b34fb"), "(os)")
    t.join()
    check("paired device may use a service without asking", r, {"ok": ()})
    t, r = agent_call(conn, sender, "AuthorizeService", (DEV_NEW, "0000110b-0000-1000-8000-00805f9b34fb"), "(os)")
    ev = h.event()
    check("unpaired device is asked about a service", (ev["kind"], ev["uuid"][:8]), ("service", "0000110b"))
    h.answer(ev["id"], False)
    t.join()
    check("service refused", r, {"err": "org.bluez.Error.Rejected"})

    t, r = agent_call(conn, sender, "DisplayPasskey", (DEV_NEW, 987, 3), "(ouq)")
    ev = h.event()
    check("display event", (ev["event"], ev["code"], ev["entered"]), ("display", "000987", 3))
    t.join()
    check("display returns at once", r, {"ok": ()})

    t, r = agent_call(conn, sender, "RequestConfirmation", (DEV_NEW, 7), "(ou)")
    h.event()
    cancel = agent_call(conn, sender, "Cancel", (), "()")
    cancel[0].join()
    t.join()
    check("cancel tells the shell", h.event(), {"event": "cancel"})
    check("cancel fails the waiting request", r, {"err": "org.bluez.Error.Canceled"})

    t, r = agent_call(conn, sender, "RequestConfirmation", (DEV_NEW, 9), "(ou)")
    ev = h.event()
    t.join()
    check("no answer is a refusal", r, {"err": "org.bluez.Error.Rejected"})
    check("no answer tells the shell", h.event(), {"event": "cancel", "id": ev["id"]})

    strict = Helper(any_sender=False)
    strict.event()
    t, r = agent_call(conn, strict_sender(strict), "RequestConfirmation", (DEV_NEW, 5), "(ou)")
    t.join()
    check("a caller that isn't bluetoothd is refused", r, {"err": "org.bluez.Error.Rejected"})
    check("and nothing reaches the shell", strict.event(timeout=1), None)
    strict.p.stdin.close()
    strict.p.wait(timeout=5)

    h.p.stdin.close()
    check("exits when the shell closes stdin", h.p.wait(timeout=5), 0)
    check("unregisters on the way out", wait_log("unregister ") is not None)

    fake.terminate()
    print("%d passed, %d failed" % (passed, failed))
    return 1 if failed else 0

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "fake":
        run_fake()
    else:
        sys.exit(main())
