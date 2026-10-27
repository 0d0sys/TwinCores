// Round 14 stage probe - run via: Rainmeter.exe !CommandMeasure MeasureWebView "Execute <path>"
// Reports the video element's true state into the Rainmeter log.
(function () {
  try {
    var v = document.getElementById('v');
    if (!v) { RainmeterAPI.Log('STAGE-PROBE: no #v element', 'NOTICE'); return; }
    var err = v.error ? (v.error.code + '/' + v.error.message) : 'none';
    var cs = getComputedStyle(v);
    RainmeterAPI.Log('STAGE-PROBE readyState=' + v.readyState + ' paused=' + v.paused + ' err=' + err +
      ' netState=' + v.networkState + ' size=' + v.videoWidth + 'x' + v.videoHeight +
      ' opacity=' + cs.opacity + ' cls=' + v.className +
      ' visState=' + document.visibilityState + ' src=' + (v.src || '').slice(0, 80), 'NOTICE');
    RainmeterAPI.Log('STAGE-PROBE body-size=' + document.body.clientWidth + 'x' + document.body.clientHeight +
      ' dpr=' + window.devicePixelRatio + ' hidden=' + document.hidden, 'NOTICE');
  } catch (e) {
    try { RainmeterAPI.Log('STAGE-PROBE exception: ' + e, 'NOTICE'); } catch (x) {}
  }
})();
