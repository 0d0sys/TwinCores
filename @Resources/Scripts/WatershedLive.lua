-- WatershedLive.lua - ambient live layer over the watershed plate.
-- Fireflies = activity in the forest (monitor 1). Flow streaks = the crest
-- current, speed = load. Plankton drift and glow in the deep (monitor 2).
-- One traveling pulse runs source -> deep, its speed = load. LUMEN = LOAD.

local flies, plankton, streaks = {}, {}, {}
local pulseX, pulseGlow = 0, 0

local f1, f2, fy1, fy2
local s1, s2, sy1, sy2
local p1, p2, py1, py2
local px1, px2, py

local function num(v, d)
  local n = tonumber(SKIN:GetVariable(v))
  return n or d
end

local function rr(a, b) return a + math.random() * (b - a) end

function Initialize()
  f1 = num('FireflyX1', 80); f2 = num('FireflyX2', 1900)
  fy1 = num('FireflyY1', 140); fy2 = num('FireflyY2', 880)
  s1 = num('StreakX1', 2050); s2 = num('StreakX2', 2950)
  sy1 = num('StreakY1', 620); sy2 = num('StreakY2', 990)
  p1 = num('PlanktonX1', 3050); p2 = num('PlanktonX2', 3820)
  py1 = num('PlanktonY1', 80); py2 = num('PlanktonY2', 1010)
  px1 = num('PulseX1', 260); px2 = num('PulseX2', 3620)
  py = num('PulseY', 560)

  for i = 1, 16 do
    flies[i] = { x = rr(f1, f2), y = rr(fy1, fy2), vx = rr(-0.35, 0.35),
                 vy = rr(-0.25, 0.25), ph = rr(0, 6.28), r = rr(1.5, 3) }
  end
  for i = 1, 12 do
    plankton[i] = { x = rr(p1, p2), y = rr(py1, py2), vy = rr(0.15, 0.55),
                    ph = rr(0, 6.28), r = rr(1.2, 2.4) }
  end
  for i = 1, 8 do
    streaks[i] = { x = rr(s1, s2), y = rr(sy1, sy2), len = rr(26, 64), v = rr(0.8, 1.7) }
  end
  pulseX = px1
end

function Update()
  local lv = tonumber(SKIN:GetVariable('Lumen')) or 0.15
  local t = os.clock()

  -- fireflies: wander the forest, brightness and pace rise with load
  for i, fl in ipairs(flies) do
    local spd = 0.5 + lv * 2.2
    fl.x = fl.x + fl.vx * spd; fl.y = fl.y + fl.vy * spd
    if fl.x < f1 or fl.x > f2 then fl.vx = -fl.vx; fl.x = math.max(f1, math.min(f2, fl.x)) end
    if fl.y < fy1 or fl.y > fy2 then fl.vy = -fl.vy; fl.y = math.max(fy1, math.min(fy2, fl.y)) end
    local flick = 0.5 + 0.5 * math.sin(t * (1.2 + lv * 3.5) + fl.ph)
    local a = math.floor((20 + 210 * lv) * flick + 8)
    local xi, yi = math.floor(fl.x), math.floor(fl.y)
    local r1 = string.format('%.1f', fl.r)
    SKIN:Bang('!SetOption', 'Fly' .. i, 'Shape',
      'Ellipse ' .. xi .. ',' .. yi .. ',' .. r1 ..
      ' | Fill Color 216,255,190,' .. a .. ' | StrokeWidth 0')
    SKIN:Bang('!SetOption', 'Fly' .. i, 'Shape2',
      'Ellipse ' .. xi .. ',' .. yi .. ',' .. string.format('%.1f', fl.r * 4) ..
      ' | Fill Color 150,220,160,' .. math.floor(a / 7 + 6) .. ' | StrokeWidth 0')
  end

  -- plankton: marine snow drifting down in the deep, never blinking
  for i, m in ipairs(plankton) do
    m.y = m.y + m.vy * (0.4 + lv * 1.6)
    if m.y > py2 then m.y = py1; m.x = rr(p1, p2) end
    local tw = 0.5 + 0.5 * math.sin(t * (0.8 + lv * 2) + m.ph)
    local a = math.floor((16 + 130 * lv) * tw + 6)
    local xi, yi = math.floor(m.x), math.floor(m.y)
    SKIN:Bang('!SetOption', 'Mote' .. i, 'Shape',
      'Ellipse ' .. xi .. ',' .. yi .. ',' .. string.format('%.1f', m.r) ..
      ' | Fill Color 190,232,255,' .. a .. ' | StrokeWidth 0')
    SKIN:Bang('!SetOption', 'Mote' .. i, 'Shape2',
      'Ellipse ' .. xi .. ',' .. yi .. ',' .. string.format('%.1f', m.r * 3.2) ..
      ' | Fill Color 140,200,235,' .. math.floor(a / 8 + 4) .. ' | StrokeWidth 0')
  end

  -- flow streaks: run downstream through the crest, speed = load
  for i, s in ipairs(streaks) do
    s.x = s.x + s.v * (0.6 + lv * 5.5)
    if s.x > s2 then s.x = s1 - rr(0, 120); s.y = rr(sy1, sy2) end
    local a = math.floor(26 + 100 * lv)
    local xa, ya, xb = math.floor(s.x), math.floor(s.y), math.floor(s.x + s.len)
    SKIN:Bang('!SetOption', 'Streak' .. i, 'Shape',
      'Line ' .. xa .. ',' .. ya .. ',' .. xb .. ',' .. ya ..
      ' | Stroke Color 140,200,205,' .. a .. ' | StrokeWidth 1')
  end

  -- the traveling pulse: one lit seed running source -> deep
  pulseX = pulseX + (0.6 + lv * 26)
  if pulseX > px2 then pulseX = px1; pulseGlow = 1 end
  pulseGlow = pulseGlow * 0.9
  local pa = math.floor(120 + 120 * pulseGlow + 60 * lv)
  local xi = math.floor(pulseX)
  SKIN:Bang('!SetOption', 'Pulse', 'Shape',
    'Ellipse ' .. xi .. ',' .. py .. ',4 | Fill Color 255,244,200,' .. pa .. ' | StrokeWidth 0')
  SKIN:Bang('!SetOption', 'Pulse', 'Shape2',
    'Ellipse ' .. xi .. ',' .. py .. ',14 | Fill Color 255,220,150,' .. math.floor(pa / 5) .. ' | StrokeWidth 0')
end
