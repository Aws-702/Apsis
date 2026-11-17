#!/usr/bin/env python3
# The shell's Bluetooth pairing agent: registers with BlueZ and talks JSON lines with BtAgent.qml.
# Edit: CAPABILITY for how pairing is asked, APSIS_BT_TIMEOUT (seconds) for how long a question waits.

import json
import os
import signal
import sys
import threading

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

AGENT_PATH = "/org/apsis/BtAgent"
CAPABILITY = "DisplayYesNo"
BLUEZ = "org.bluez"
ANSWER_TIMEOUT = int(os.environ.get("APSIS_BT_TIMEOUT", "60"))

AGENT_XML = """
<node>
  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode">
      <arg type="o" direction="in"/>
      <arg type="s" direction="out"/>
    </method>
    <method name="DisplayPinCode">
      <arg type="o" direction="in"/>
      <arg type="s" direction="in"/>
    </method>
    <method name="RequestPasskey">
      <arg type="o" direction="in"/>
      <arg type="u" direction="out"/>
    </method>
    <method name="DisplayPasskey">
      <arg type="o" direction="in"/>
      <arg type="u" direction="in"/>
      <arg type="q" direction="in"/>
    </method>
    <method name="RequestConfirmation">
      <arg type="o" direction="in"/>
      <arg type="u" direction="in"/>
    </method>
    <method name="RequestAuthorization">
      <arg type="o" direction="in"/>
    </method>
    <method name="AuthorizeService">
      <arg type="o" direction="in"/>
      <arg type="s" direction="in"/>
    </method>
    <method name="Cancel"/>
  </interface>
</node>
"""

ERR_REJECTED = "org.bluez.Error.Rejected"
ERR_CANCELED = "org.bluez.Error.Canceled"

def emit(obj):
    sys.stdout.write(json.dumps(obj, separators=(",", ":")) + "\n")
    sys.stdout.flush()

def signal_add(sig, fn):
    try:
        gi.require_version("GLibUnix", "2.0")
        from gi.repository import GLibUnix
        GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, sig, fn)
    except (ValueError, ImportError, AttributeError):
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, sig, fn)

class Agent:
    def __init__(self, bus_type):
        self.bus_type = bus_type
        self.conn = None
        self.reg_id = 0
        self.registered = False
        self.pending = {}
        self.next_id = 1
        self.loop = GLib.MainLoop()
        self.watch = 0
        self.bluez_owner = None
        self.any_sender = os.environ.get("APSIS_BT_ANY_SENDER") == "1"

    def start(self):
        self.conn = Gio.bus_get_sync(self.bus_type, None)
        node = Gio.DBusNodeInfo.new_for_xml(AGENT_XML)
        self.reg_id = self.conn.register_object(
            AGENT_PATH, node.interfaces[0], self.on_method_call, None, None)
        self.watch = Gio.bus_watch_name_on_connection(
            self.conn, BLUEZ, Gio.BusNameWatcherFlags.NONE,
            self.on_bluez_appeared, self.on_bluez_vanished)
        threading.Thread(target=self.read_stdin, daemon=True).start()
        for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            signal_add(sig, self.quit)
        self.loop.run()

    def quit(self, *_):
        self.cancel_all(reject=True)
        if self.registered:
            try:
                self.conn.call_sync(BLUEZ, "/org/bluez", "org.bluez.AgentManager1",
                                    "UnregisterAgent", GLib.Variant("(o)", (AGENT_PATH,)),
                                    None, Gio.DBusCallFlags.NONE, 1000, None)
            except GLib.Error:
                pass
        self.loop.quit()
        return False

    def on_bluez_appeared(self, conn, name, owner):
        self.bluez_owner = owner
        def done(source, res):
            try:
                source.call_finish(res)
            except GLib.Error as e:
                self.registered = False
                emit({"event": "error", "message": "could not register: " + e.message})
                return
            self.request_default()
        conn.call(BLUEZ, "/org/bluez", "org.bluez.AgentManager1", "RegisterAgent",
                  GLib.Variant("(os)", (AGENT_PATH, CAPABILITY)), None,
                  Gio.DBusCallFlags.NONE, 5000, None, done)

    def request_default(self):
        def done(source, res):
            try:
                source.call_finish(res)
            except GLib.Error as e:
                self.registered = False
                emit({"event": "error", "message": "could not become the default agent: " + e.message})
                return
            self.registered = True
            emit({"event": "registered"})
        self.conn.call(BLUEZ, "/org/bluez", "org.bluez.AgentManager1", "RequestDefaultAgent",
                       GLib.Variant("(o)", (AGENT_PATH,)), None,
                       Gio.DBusCallFlags.NONE, 5000, None, done)

    def on_bluez_vanished(self, conn, name):
        if self.registered:
            self.registered = False
            emit({"event": "unregistered"})
        self.cancel_all(reject=False)

    def read_stdin(self):
        for line in sys.stdin:
            line = line.strip()
            if line:
                GLib.idle_add(self.on_answer, line)
        GLib.idle_add(self.quit)

    def on_answer(self, line):
        try:
            msg = json.loads(line)
            rid = int(msg["id"])
        except (ValueError, KeyError, TypeError):
            return False
        p = self.pending.get(rid)
        if p is None:
            return False
        self.finish(rid, bool(msg.get("accept")), msg.get("value"))
        return False

    def device_info(self, path):
        info = {"name": "", "address": "", "paired": False}
        try:
            res = self.conn.call_sync(
                BLUEZ, path, "org.freedesktop.DBus.Properties", "GetAll",
                GLib.Variant("(s)", ("org.bluez.Device1",)), GLib.VariantType("(a{sv})"),
                Gio.DBusCallFlags.NONE, 2000, None)
            props = res.unpack()[0]
            info["name"] = str(props.get("Alias") or props.get("Name") or "")
            info["address"] = str(props.get("Address") or "")
            info["paired"] = bool(props.get("Paired"))
        except GLib.Error:
            pass
        if not info["name"]:
            info["name"] = info["address"] or path.rsplit("/", 1)[-1].replace("dev_", "").replace("_", ":")
        return info

    def trust(self, path):
        self.conn.call(BLUEZ, path, "org.freedesktop.DBus.Properties", "Set",
                       GLib.Variant("(ssv)", ("org.bluez.Device1", "Trusted", GLib.Variant("b", True))),
                       None, Gio.DBusCallFlags.NONE, 2000, None, lambda s, r: self.swallow(s, r))

    @staticmethod
    def swallow(source, res):
        try:
            source.call_finish(res)
        except GLib.Error:
            pass

    def ask(self, invocation, kind, path, **extra):
        rid = self.next_id
        self.next_id += 1
        info = self.device_info(path)
        timer = GLib.timeout_add_seconds(ANSWER_TIMEOUT, self.on_timeout, rid)
        self.pending[rid] = {"inv": invocation, "kind": kind, "path": path, "timer": timer}
        msg = {"event": "request", "id": rid, "kind": kind,
               "name": info["name"], "address": info["address"]}
        msg.update(extra)
        emit(msg)

    def on_timeout(self, rid):
        if rid in self.pending:
            self.finish(rid, False, None, timed_out=True)
        return False

    def finish(self, rid, accept, value, timed_out=False):
        p = self.pending.pop(rid, None)
        if p is None:
            return
        if not timed_out:
            GLib.source_remove(p["timer"])
        inv, kind, path = p["inv"], p["kind"], p["path"]
        if not accept:
            inv.return_dbus_error(ERR_REJECTED, "rejected")
            if timed_out:
                emit({"event": "cancel", "id": rid})
            return
        if kind == "pin":
            text = str(value if value is not None else "")
            if not text or len(text) > 16:
                inv.return_dbus_error(ERR_REJECTED, "bad PIN")
                return
            inv.return_value(GLib.Variant("(s)", (text,)))
        elif kind == "passkey":
            try:
                n = int(str(value))
                if not 0 <= n <= 999999:
                    raise ValueError
            except ValueError:
                inv.return_dbus_error(ERR_REJECTED, "bad passkey")
                return
            inv.return_value(GLib.Variant("(u)", (n,)))
        else:
            inv.return_value(None)
        if kind in ("confirm", "pin", "passkey", "authorize"):
            self.trust(path)

    def cancel_all(self, reject):
        pend, self.pending = self.pending, {}
        for p in pend.values():
            GLib.source_remove(p["timer"])
            if reject:
                p["inv"].return_dbus_error(ERR_CANCELED, "canceled")
        if pend:
            emit({"event": "cancel"})

    def on_method_call(self, conn, sender, path, iface, method, params, inv):
        if not self.any_sender and sender != self.bluez_owner:
            inv.return_dbus_error(ERR_REJECTED, "only bluetoothd may ask")
            return
        args = params.unpack()
        if method == "Release":
            self.registered = False
            emit({"event": "unregistered"})
            inv.return_value(None)
        elif method == "Cancel":
            self.cancel_all(reject=True)
            inv.return_value(None)
        elif method == "RequestConfirmation":
            self.ask(inv, "confirm", args[0], code="%06d" % args[1])
        elif method == "RequestAuthorization":
            self.ask(inv, "authorize", args[0])
        elif method == "RequestPinCode":
            self.ask(inv, "pin", args[0])
        elif method == "RequestPasskey":
            self.ask(inv, "passkey", args[0])
        elif method == "AuthorizeService":
            if self.device_info(args[0])["paired"]:
                inv.return_value(None)
            else:
                self.ask(inv, "service", args[0], uuid=args[1])
        elif method == "DisplayPinCode":
            info = self.device_info(args[0])
            emit({"event": "display", "name": info["name"], "address": info["address"],
                  "code": str(args[1]), "entered": 0})
            inv.return_value(None)
        elif method == "DisplayPasskey":
            info = self.device_info(args[0])
            emit({"event": "display", "name": info["name"], "address": info["address"],
                  "code": "%06d" % args[1], "entered": int(args[2])})
            inv.return_value(None)
        else:
            inv.return_dbus_error("org.freedesktop.DBus.Error.UnknownMethod", method)

def main():
    bus = Gio.BusType.SESSION if os.environ.get("APSIS_BT_BUS") == "session" else Gio.BusType.SYSTEM
    try:
        Agent(bus).start()
    except GLib.Error as e:
        emit({"event": "error", "message": e.message})
        sys.exit(1)

if __name__ == "__main__":
    main()
