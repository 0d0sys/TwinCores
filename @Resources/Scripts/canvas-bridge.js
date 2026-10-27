// canvas-bridge.js - TwinCores Watershed Spicetify extension.
// On every song change it resolves the current track's Canvas video
// URL and POSTs it to the local Rainmeter bridge server:
//   1. cheap path: track metadata often already carries canvas.canvasUri
//   2. fallback: protobuf request to spclient canvaz-cache/v0/canvases
//      (same recipe as the proven Spicetify-Canvas extension)
// The protobuf encode/decode below is hand-rolled (no CDN dependency):
//   EntityCanvazRequest  { repeated Entity entities = 1; }
//   Entity               { string entity_uri = 1; }
//   EntityCanvazResponse { repeated Canvaz canvases = 1; }
//   Canvaz               { string id = 1; string url = 2; ... int type = 4;
//                          string entity_uri = 5; }
(() => {
  const BRIDGE = 'http://127.0.0.1:8795/canvas';
  const TAG = '[TwinCoresCanvas]';

  const waitSpicetify = async () => {
    for (let i = 0; i < 150; i++) {
      if (window.Spicetify && Spicetify.Player && Spicetify.CosmosAsync) return;
      await new Promise((r) => setTimeout(r, 200));
    }
  };

  // --- minimal protobuf wire helpers ---
  const varint = (n) => {
    const out = [];
    do { let b = n & 0x7f; n >>>= 7; if (n) b |= 0x80; out.push(b); } while (n);
    return out;
  };
  const bytesField = (fieldNo, bytes) => [
    (fieldNo << 3) | 2, ...varint(bytes.length), ...bytes,
  ];

  function encodeRequest(uri) {
    const uriBytes = [...new TextEncoder().encode(uri)];
    const entity = bytesField(1, uriBytes);          // Entity.entity_uri
    return new Uint8Array(bytesField(1, entity));    // Request.entities
  }

  function decodeCanvases(buf) {
    const out = [];
    let i = 0;
    const readVarint = () => {
      let v = 0, s = 0;
      for (;;) {
        const b = buf[i++];
        v += (b & 0x7f) * Math.pow(2, s);
        if (!(b & 0x80)) return v;
        s += 7;
      }
    };
    const readBytes = () => {
      const len = readVarint();
      const a = buf.slice(i, i + len);
      i += len;
      return a;
    };
    while (i < buf.length) {
      const tag = readVarint();
      const field = tag >>> 3, wire = tag & 7;
      if (field === 1 && wire === 2) {
        const msg = readBytes();
        const canvas = { url: '', type: -1, entityUri: '' };
        let j = 0;
        const mVarint = () => {
          let v = 0, s = 0;
          for (;;) {
            const b = msg[j++];
            v += (b & 0x7f) * Math.pow(2, s);
            if (!(b & 0x80)) return v;
            s += 7;
          }
        };
        while (j < msg.length) {
          const t = mVarint();
          const f = t >>> 3, w = t & 7;
          if (w === 2) {
            const len = mVarint();
            const val = new TextDecoder().decode(msg.slice(j, j + len));
            j += len;
            if (f === 2) canvas.url = val;
            else if (f === 5) canvas.entityUri = val;
          } else if (w === 0) {
            const val = mVarint();
            if (f === 4) canvas.type = val;
          } else if (w === 5) j += 4;
          else if (w === 1) j += 8;
          else break;
        }
        if (canvas.url) out.push(canvas);
      } else if (wire === 2) readBytes();
      else if (wire === 0) readVarint();
      else if (wire === 5) i += 4;
      else if (wire === 1) i += 8;
      else break;
    }
    return out;
  }

  // Round 14 telemetry: every failure/empty path now reports to the bridge
  // log endpoint so the pipeline can be debugged from canvas-log.txt.
  function logLine(entry) {
    try {
      fetch('http://127.0.0.1:8795/log', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(entry),
      });
    } catch (l) {}
  }

  let probed = false;
  function probeAuth() {
    // one-time capability report so future breakages are one look, not an hour
    if (probed) return;
    probed = true;
    try {
      var a = Spicetify.Platform && Spicetify.Platform.AuthorizationAPI;
      var shapes = {};
      if (a) {
        Object.keys(a).forEach(function (k) {
          var v = a[k];
          var t = typeof v;
          if (t === 'object' && v !== null) {
            try { t += '[' + Object.keys(v).slice(0, 15).join(',') + ']'; } catch (x) {}
          }
          shapes[k] = t;
        });
        var tp = a._tokenProvider;
        if (tp && Object.getPrototypeOf(tp)) {
          shapes.tpProto = Object.getOwnPropertyNames(Object.getPrototypeOf(tp)).join(',');
        }
        var st = a._state && a._state.token;
        shapes.stateTokenType = typeof st;
        if (typeof st === 'string') shapes.stateTokenLen = st.length;
      }
      logLine({
        src: 'ext', ev: 'auth-probe',
        getAccessToken: typeof Spicetify.getAccessToken,
        authApi: a ? Object.keys(a).join(',') : 'absent',
        shapes: JSON.stringify(shapes).slice(0, 1200),
      });
    } catch (e) {}
  }

  async function getToken() {
    probeAuth();
    const A = Spicetify.Platform.AuthorizationAPI;
    // 1. AuthorizationAPI._state.token (2026 client shape)
    try {
      const t = A._state && A._state.token;
      if (typeof t === 'string' && t.length > 20) return t;
      if (t && typeof t.then === 'function') {
        const r = await t;
        if (r && r.accessToken) return r.accessToken;
        if (typeof r === 'string' && r.length > 20) return r;
      }
    } catch (e) {
      logLine({ src: 'ext', ev: 'state-token-fail', err: String(e) });
    }
    // 2. TokenProvider instance prototype method
    try {
      const tp = A._tokenProvider;
      const name = ['getToken', 'provide', 'get', 'getTokenForRequest'].find(function (n) {
        return tp && typeof tp[n] === 'function';
      });
      if (name) {
        const r = await tp[name]({ preferCached: true });
        if (r && r.accessToken) return r.accessToken;
        if (typeof r === 'string' && r.length > 20) return r;
      }
    } catch (e) {
      logLine({ src: 'ext', ev: 'tp-fail', err: String(e) });
    }
    // 3. stable Spicetify API (older clients)
    try {
      const t = Spicetify.getAccessToken();
      if (t) return t;
    } catch (e) {}
    // 4. internal cosmos authorization endpoint (older clients)
    try {
      const j = await Spicetify.CosmosAsync.get('sp://authorization/v1/token');
      if (j && j.accessToken) return j.accessToken;
    } catch (e) {}
    // 5. legacy internal provider call (oldest clients)
    const r = await A._tokenProvider({ preferCached: true });
    return r.accessToken;
  }

  async function fetchCanvasUrls(uri) {
    let token = '';
    try {
      token = await getToken();
    } catch (e) {
      logLine({ src: 'ext', ev: 'token-fail', err: String(e) });
      return [];
    }
    let loc;
    try {
      loc = await (await fetch('https://apresolve.spotify.com/?type=spclient')).json();
    } catch (e) {
      logLine({ src: 'ext', ev: 'apresolve-fail', err: String(e) });
      return [];
    }
    const hosts = loc.spclient || [];
    if (!hosts.length) {
      logLine({ src: 'ext', ev: 'no-hosts' });
      return [];
    }
    const host = hosts[Math.floor(Math.random() * hosts.length)];
    let res;
    try {
      res = await fetch('https://' + host + '/canvaz-cache/v0/canvases', {
        method: 'POST',
        headers: {
          Authorization: 'Bearer ' + token,
          'Content-Type': 'application/x-protobuf',
        },
        body: encodeRequest(uri),
      });
    } catch (e) {
      logLine({ src: 'ext', ev: 'post-fail', err: String(e), host: host });
      return [];
    }
    const buf = new Uint8Array(await res.arrayBuffer());
    if (!res.ok) {
      logLine({ src: 'ext', ev: 'http-error', status: res.status, bytes: buf.length });
      return [];
    }
    const list = decodeCanvases(buf);
    if (!list.length) {
      // log first bytes so a wire-format surprise is visible
      const hex = Array.from(buf.slice(0, 24)).map(function (b) { return b.toString(16); }).join(',');
      logLine({ src: 'ext', ev: 'decode-empty', bytes: buf.length, head: hex });
    }
    return list;
  }

  async function push() {
    try {
      const data = Spicetify.Player.data;
      if (!data || !data.item || !data.item.uri) return;
      const uri = data.item.uri;
      const meta = data.item.metadata || {};
      let url = meta['canvas.canvasUri'] || meta['canvas.url'] || '';
      let source = 'metadata';
      // Round 14: the cheap metadata field can be a spotify:canvas:
      // protocol URI - NOT playable by the stage's <video> element.
      // Only accept real http(s) URLs; otherwise fall through to the
      // canvaz protobuf endpoint, whose url field IS a playable URL.
      if (url.indexOf('http') !== 0) url = '';
      if (!url) {
        source = 'protobuf';
        const list = await fetchCanvasUrls(uri);
        if (list.length) url = list[0].url;
        else source = 'protobuf-empty';
      }
      logLine({ src: 'ext', source: source, url: url.slice(0, 120), track: uri });
      await fetch(BRIDGE, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          url: url,
          track: uri,
          title: meta.title || '',
        }),
      });
      console.log(TAG, 'pushed', uri, url ? 'canvas' : 'no-canvas');
    } catch (e) {
      console.log(TAG, 'push failed', e);
    }
  }

  (async () => {
    await waitSpicetify();
    Spicetify.Player.addEventListener('songchange', push);
    setTimeout(push, 1500);
    // re-push periodically: canvas URLs expire, and a manual track
    // restart does not fire songchange
    setInterval(push, 10 * 60 * 1000);
  })();
})();
