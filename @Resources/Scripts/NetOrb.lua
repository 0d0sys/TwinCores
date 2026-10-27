-- NetOrb.lua - status orb shared by NETWORK (Core-Ember spot, M1)
-- and PROTON VPN (Core-Glem spot, M2). Skin variable OrbMode selects:
--   NET -> wired / wi-fi / offline + live down/up speed
--   VPN -> tracks the Proton VPN 'ProTUN' tunnel adapter
-- NOTE: Rainmeter's Lua sandbox has NO io.popen / os.execute, so the
-- interface poll runs through the RunCommand plugin (MeasurePoll,
-- hidden cmd, output captured as the measure string value; its
-- FinishAction calls Polled()). Poll every 5 s.
-- Glow = connection state (bright + load pulse when up, dim when down);
-- pulse rate still rides LUMEN (load).

local pollEvery = 5
local tick = 0
local phase = 0
local mode = 'NET'
local state = {}
local pending = false
local pendingAt = 0

function Initialize()
  mode = string.upper(SKIN:GetVariable('OrbMode') or 'NET')
end

function Polled()
  pending = false
  local m = SKIN:GetMeasure('MeasurePoll')
  if not m then return end
  local out = m:GetStringValue() or ''
  local list = {}
  for line in out:gmatch('[^\r\n]+') do
    local st, name = line:match('%s(Connected)%s+%S+%s+(.-)%s*$')
    if not st then
      st, name = line:match('%s(Disconnected)%s+%S+%s+(.-)%s*$')
    end
    if st and name and name ~= '' then
      list[string.lower(name)] = string.lower(st)
    end
  end
  state = list
  Draw()
end

function Update()
  tick = tick + 1
  -- a refresh can kill a running poll before FinishAction fires, so a
  -- stale pending flag must never wedge the loop: force-expire it
  if pending and tick - pendingAt > pollEvery then pending = false end
  -- first Run waits one tick (skin still settling right after refresh)
  if not pending and (tick == 2 or tick % pollEvery == 1) then
    pending = true
    pendingAt = tick
    SKIN:Bang('!CommandMeasure', 'MeasurePoll', 'Run')
  end
  Draw()
end

function Debug()
  -- temporary: dump raw poll output + parsed state to a file
  local m = SKIN:GetMeasure('MeasurePoll')
  local out = m and m:GetStringValue() or 'NO MEASURE'
  local f = io.open(SKIN:GetVariable('@') .. 'Data\\netorb-debug.txt', 'wb')
  if f then
    f:write('mode=' .. mode .. ' pending=' .. tostring(pending) .. '\n')
    f:write('rawlen=' .. #out .. '\n')
    f:write('raw=[' .. out .. ']\n')
    for k, v in pairs(state) do f:write(k .. '=' .. v .. '\n') end
    f:close()
  end
end

function Draw()
  local lv = tonumber(SKIN:GetVariable('Lumen')) or 0.15
  local col = SKIN:GetVariable('CoreColor')
  local on = false
  local line1 = 'CHECK'
  local line2 = ''

  if mode == 'VPN' then
    on = (state['protun'] == 'connected')
    line1 = on and 'VPN ON' or 'VPN OFF'
    line2 = on and 'TUNNEL ACTIVE' or 'TUNNEL DOWN'
  else
    local wired = state['ethernet'] == 'connected'
    local wifi = state['wi-fi'] == 'connected'
    if wired then on = true; line1 = 'WIRED'
    elseif wifi then on = true; line1 = 'WI-FI'
    else line1 = 'OFFLINE' end
    local din = SKIN:GetMeasure('CalcNetIn')
    local dout = SKIN:GetMeasure('CalcNetOut')
    if din and dout then
      -- NOTE: the Lua measure API is GetValue() / GetStringValue() -
      -- there is no GetNumberValue (cost an hour of blank orb to learn)
      line2 = string.format('D %.0f  U %.0f KB/S', din:GetValue(), dout:GetValue())
    end
  end

  -- glow: up = bright steady + load pulse, down = dim ember
  local cx = tonumber(SKIN:GetVariable('OrbCX')) or 75
  local cy = tonumber(SKIN:GetVariable('OrbCY')) or 75
  local r = tonumber(SKIN:GetVariable('OrbR')) or 62
  phase = phase + (0.05 + lv * 0.9) * (on and 1.0 or 0.55)
  local s = 0.5 + 0.5 * math.sin(phase)
  local a1, a2
  if on then
    a1 = math.floor(120 + 90 * s * (0.35 + lv))
    a2 = math.floor(45 + 70 * s * (0.3 + lv))
  else
    a1 = math.floor(25 + 55 * s * (0.35 + lv))
    a2 = math.floor(10 + 25 * s * (0.3 + lv))
  end
  SKIN:Bang('!SetOption', 'PulseRing', 'Shape',
    'Ellipse ' .. cx .. ',' .. cy .. ',' .. (r + 9) .. ' | Fill Color 0,0,0,1 | Stroke Color ' .. col .. ',' .. a1 .. ' | StrokeWidth 3')
  SKIN:Bang('!SetOption', 'HaloRing', 'Shape',
    'Ellipse ' .. cx .. ',' .. cy .. ',' .. (r + 23) .. ' | Fill Color 0,0,0,1 | Stroke Color ' .. col .. ',' .. a2 .. ' | StrokeWidth 1')

  SKIN:Bang('!SetOption', 'StateText', 'Text', line1)
  SKIN:Bang('!SetOption', 'StateText', 'FontColor',
    (on and SKIN:GetVariable('TextC') or SKIN:GetVariable('DimC')) .. (on and ',240' or ',150'))
  if line2 ~= '' then
    SKIN:Bang('!SetOption', 'DetailText', 'Text', line2)
    SKIN:Bang('!SetOption', 'DetailText', 'Hidden', 0)
  else
    SKIN:Bang('!SetOption', 'DetailText', 'Hidden', 1)
  end

  SKIN:Bang('!UpdateMeter', 'PulseRing')
  SKIN:Bang('!UpdateMeter', 'HaloRing')
  SKIN:Bang('!UpdateMeter', 'StateText')
  SKIN:Bang('!UpdateMeter', 'DetailText')
  SKIN:Bang('!Redraw')
end
