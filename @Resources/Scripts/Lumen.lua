-- Lumen.lua - LUMEN = LOAD hub for the Watershed suite.
-- Reads CPU + RAM, smooths into one load level (0..1), and broadcasts
-- it as the Lumen / LoadPct / GlowA variables to every Watershed skin.
-- One physics law: idle = candle, load = bonfire.

local smooth = 0.15
local lastSent = -1
local lastTime = 0

local targets = {
  'TwinCores\\Watershed\\Primary', 'TwinCores\\Watershed\\Secondary',
  'TwinCores\\Watershed\\Art', 'TwinCores\\Watershed\\Agenda',
  'TwinCores\\Watershed\\Memos', 'TwinCores\\Watershed\\System',
  'TwinCores\\Watershed\\Core-Ember', 'TwinCores\\Watershed\\Core-Glem',
  'TwinCores\\Watershed\\Live'
}

local function readNum(name)
  local m = SKIN:GetMeasure(name)
  if not m then return 0 end
  local v = tonumber(m:GetValue()) or tonumber(m:GetStringValue()) or 0
  return v
end

function Update()
  local cpu = readNum('MeasureCPU')
  local ram = readNum('CalcRAM')
  local load = math.min(1, math.max(cpu, ram) / 100)

  -- ease toward the new level (rising faster than falling, like real light)
  local rate = load > smooth and 0.30 or 0.10
  smooth = smooth + (load - smooth) * rate

  local now = os.clock()
  local changed = math.abs(smooth - lastSent) > 0.015
  if changed or (now - lastTime) > 4 then
    local l = string.format('%.3f', smooth)
    local pct = math.floor(smooth * 100 + 0.5)
    local ga = math.floor(28 + 150 * smooth)
    local ga2 = math.floor(8 + 42 * smooth)

    -- self (so any meter in this skin can read it too)
    SKIN:Bang('!SetVariable', 'Lumen', l)
    SKIN:Bang('!SetVariable', 'LoadPct', tostring(pct))
    SKIN:Bang('!SetVariable', 'GlowA', tostring(ga))
    SKIN:Bang('!SetVariable', 'GlowA2', tostring(ga2))

    for _, t in ipairs(targets) do
      SKIN:Bang('!SetVariable', 'Lumen', l, t)
      SKIN:Bang('!SetVariable', 'LoadPct', tostring(pct), t)
      SKIN:Bang('!SetVariable', 'GlowA', tostring(ga), t)
      SKIN:Bang('!SetVariable', 'GlowA2', tostring(ga2), t)
    end

    -- only the animated skins need an extra redraw kick
    for _, t in ipairs({ 'TwinCores\\Watershed\\Core-Ember', 'TwinCores\\Watershed\\Core-Glem', 'TwinCores\\Watershed\\Live' }) do
      SKIN:Bang('!UpdateMeter', '*', t)
      SKIN:Bang('!Redraw', t)
    end

    lastSent = smooth
    lastTime = now
  end
end
