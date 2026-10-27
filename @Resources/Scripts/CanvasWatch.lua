-- CanvasWatch.lua - polls the local canvas bridge (canvas-bridge.py,
-- port 8795) and toggles the Art panel between the video stage
-- (WebView2 measure) and the album-cover fallback.
-- Poll cadence ~4 s; staleness guard per bookmark fact 31.

local pollEvery = 4
local tick = 0
local pending = false
local pendingAt = 0
local lastState = -1

function Initialize()
  lastState = -1
end

function Polled()
  pending = false
  local m = SKIN:GetMeasure('MeasureCanvasPoll')
  local out = m and m:GetStringValue() or ''
  local url = out:match('"url"%s*:%s*"(.-)"') or ''
  local active = (url ~= '') and 1 or 0
  -- Round 14 debug: log ONLY flip transitions (a full per-poll dump floods the file)
  if active ~= lastState then
    local wv = SKIN:GetMeasure('MeasureWebView')
    local wvstate = wv and wv:GetValue() or -99
    local fh = io.open('C:/Users/might/Documents/Rainmeter/Skins/TwinCores/@Resources/Data/canvaswatch-debug.txt', 'a')
    if fh then
      fh:write(os.date('%H:%M:%S'), ' FLIP active=', active, ' from=', lastState, ' webview-state=', wvstate, ' url=', url:sub(1, 60), "\n")
      fh:close()
    end
  end
  if active ~= lastState then
    lastState = active
    -- video stage on: hide cover fallback. off: show cover again.
    SKIN:Bang('!SetOption', 'MeasureWebView', 'Hidden', 1 - active)
    SKIN:Bang('!SetOption', 'Art', 'Hidden', active)
    SKIN:Bang('!SetOption', 'ArtFrame', 'Hidden', active)
    SKIN:Bang('!SetOption', 'Idle', 'Hidden', active)
    SKIN:Bang('!UpdateMeasure', 'MeasureWebView')
    SKIN:Bang('!UpdateMeter', 'Art')
    SKIN:Bang('!UpdateMeter', 'ArtFrame')
    SKIN:Bang('!UpdateMeter', 'Idle')
    SKIN:Bang('!Redraw')
  end
end

function Update()
  tick = tick + 1
  if pending and tick - pendingAt > pollEvery + 2 then pending = false end
  if not pending and (tick == 3 or tick % pollEvery == 0) then
    pending = true
    pendingAt = tick
    SKIN:Bang('!CommandMeasure', 'MeasureCanvasPoll', 'Run')
  end
end
