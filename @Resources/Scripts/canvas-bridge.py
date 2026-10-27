# canvas-bridge.py - TwinCores Watershed local bridge.
# Spicetify extension (canvas-bridge.js) POSTs the current track's
# Canvas video URL here; the Art widget's stage page (stage.html,
# served through the WebView2 virtual host) polls GET /canvas.
# Single-instance: if the port is taken the process exits silently.
import json
import os
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8795
HERE = os.path.dirname(os.path.abspath(__file__))
MIRROR = os.path.join(os.path.dirname(HERE), "Data", "canvas-state.json")

STATE = {"url": "", "track": "", "title": "", "updated": 0}
LOCK = threading.Lock()
LOGFILE = os.path.join(os.path.dirname(HERE), "Data", "canvas-log.txt")
LOGLOCK = threading.Lock()


def append_log(entry):
    """Round 14 telemetry: one JSON line per event, for debugging the canvas pipeline."""
    try:
        entry["t"] = time.strftime("%H:%M:%S")
        line = json.dumps(entry) + "\n"
        with LOGLOCK:
            with open(LOGFILE, "a", encoding="utf-8") as f:
                f.write(line)
    except Exception:
        pass


def save_mirror():
    try:
        with LOCK:
            snap = dict(STATE)
        with open(MIRROR, "w", encoding="utf-8") as f:
            json.dump(snap, f)
    except Exception:
        pass


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _send(self, code, payload, ctype="application/json"):
        body = payload if isinstance(payload, bytes) else json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        if self.path.startswith("/canvas"):
            with LOCK:
                snap = dict(STATE)
            self._send(200, snap)
        elif self.path.startswith("/ping"):
            self._send(200, {"ok": True})
        elif self.path.startswith("/log"):
            self._send(200, {"ok": True})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        try:
            data = json.loads(self.rfile.read(n) or b"{}")
        except Exception:
            self._send(400, {"error": "bad json"})
            return
        if self.path.startswith("/canvas"):
            with LOCK:
                for k in ("url", "track", "title"):
                    if k in data:
                        STATE[k] = str(data.get(k) or "")
                STATE["updated"] = time.time()
            save_mirror()
            self._send(200, {"ok": True})
        elif self.path.startswith("/log"):
            append_log(data)
            self._send(200, {"ok": True})
        else:
            self._send(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        pass  # pythonw: stay silent


def main():
    try:
        srv = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    except OSError:
        sys.exit(0)  # another instance already owns the port
    srv.serve_forever()


if __name__ == "__main__":
    main()
