-- WatershedCore.lua - pulsing edge core for EMBER / GLEM.
-- Pulse rate and brightness rise with LUMEN (load).

local phase = 0

function Update()
  local lv = tonumber(SKIN:GetVariable('Lumen')) or 0.15
  local col = SKIN:GetVariable('CoreColor')
  phase = phase + (0.05 + lv * 0.9)
  local s = 0.5 + 0.5 * math.sin(phase)
  local a1 = math.floor(45 + 150 * s * (0.35 + lv))
  local a2 = math.floor(20 + 60 * s * (0.3 + lv))
  SKIN:Bang('!SetOption', 'PulseRing', 'Shape',
    'Ellipse 60,60,46 | Fill Color 0,0,0,1 | Stroke Color ' .. col .. ',' .. a1 .. ' | StrokeWidth 2')
  SKIN:Bang('!SetOption', 'HaloRing', 'Shape',
    'Ellipse 60,60,58 | Fill Color 0,0,0,1 | Stroke Color ' .. col .. ',' .. a2 .. ' | StrokeWidth 1')
  SKIN:Bang('!UpdateMeter', 'PulseRing')
  SKIN:Bang('!UpdateMeter', 'HaloRing')
  SKIN:Bang('!Redraw')
end
