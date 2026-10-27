-- SystemGauges.lua - drives the three SYSTEM dial gauges.
-- Each update: rotate the needle (TransformationMatrix about the dial
-- center) and rebuild the value arc (endpoints on the dial circle).
-- Sweep: 270 deg gauge - value 0 = 135 deg (down-left), 1 = 45 deg
-- (down-right), clockwise through the top. Screen coords, y down:
-- point at angle T = (cx + r*cos T, cy + r*sin T), increasing T is
-- clockwise on screen.

local defs

function Initialize()
  local accent = SKIN:GetVariable('Accent')
  local accent2 = SKIN:GetVariable('Accent2')
  local accent3 = SKIN:GetVariable('Accent3')
  defs = {
    { needle = 'NeedleCPU',  arc = 'ArcCPU',  meas = 'MeasureCPU',    div = 100, cx = 95,  col = accent  },
    { needle = 'NeedleRAM',  arc = 'ArcRAM',  meas = 'CalcRAMFrac',   div = 1,   cx = 230, col = accent2 },
    { needle = 'NeedleDisk', arc = 'ArcDisk', meas = 'CalcDiskFrac',  div = 1,   cx = 365, col = accent3 },
  }
end

function Update()
  local cy = tonumber(SKIN:GetVariable('GCY')) or 150
  local r = tonumber(SKIN:GetVariable('GR')) or 52
  local redraw = false
  for _, g in ipairs(defs) do
    local m = SKIN:GetMeasure(g.meas)
    local v = ((m and m:GetValue()) or 0) / g.div
    if v < 0 then v = 0 elseif v > 1 then v = 1 end

    -- needle: rotate from pointing-up by (270*v - 135) deg clockwise
    local rot = math.rad(270 * v - 135)
    local ca, sa = math.cos(rot), math.sin(rot)
    local tx = g.cx - (ca * g.cx + (-sa) * cy)
    local ty = cy - (sa * g.cx + ca * cy)
    SKIN:Bang('!SetOption', g.needle, 'TransformationMatrix',
      string.format('%.6f;%.6f;%.6f;%.6f;%.6f;%.6f', ca, sa, -sa, ca, tx, ty))
    SKIN:Bang('!UpdateMeter', g.needle)
    redraw = true

    -- value arc: from 135 deg to (135 + 270*v) deg on the dial circle
    local a1 = math.rad(135)
    local a2 = math.rad(135 + 270 * v)
    local sx = g.cx + r * math.cos(a1)
    local sy = cy + r * math.sin(a1)
    local ex = g.cx + r * math.cos(a2)
    local ey = cy + r * math.sin(a2)
    local big = (270 * v > 180) and 1 or 0
    if v > 0.01 then
      SKIN:Bang('!SetOption', g.arc, 'Shape',
        string.format('Arc %.2f,%.2f,%.2f,%.2f,%.2f,%.2f,*,0,%d,* | Stroke Color %s,190 | StrokeWidth 6 | StrokeStartCap Round | StrokeEndCap Round',
          sx, sy, ex, ey, r, r, big, g.col))
      SKIN:Bang('!SetOption', g.arc, 'Hidden', 0)
    else
      SKIN:Bang('!SetOption', g.arc, 'Hidden', 1)
    end
    SKIN:Bang('!UpdateMeter', g.arc)
  end
  if redraw then SKIN:Bang('!Redraw') end
end
