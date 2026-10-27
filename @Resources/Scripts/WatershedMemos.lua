-- WatershedMemos.lua - click-and-type memos for the Watershed suite.
-- Three tabs backed by @Resources\Data\memo1..3.txt.
-- InputText runs at normal z-order (the on-desktop pin breaks focus).

local active = 1
local offsets = { 0, 0, 0 }
local cache = {}
local wrapped = {}
-- geometry derives from the (resized) panel: body H = MemoH-98,
-- body W = MemoW-64; LineHeight 15, char pitch ~6.9px at FontSize 10
local visible = 11
local wrapCols = 86
local tabPitch = 160
local tabW = 140

local function chars(s)
  local out = {}
  for ch in s:gmatch('[%z\1-\127\194-\244][\128-\191]*') do out[#out + 1] = ch end
  return out
end

local function wrap(s)
  local out = {}
  for line in (s:gsub('\r', '') .. '\n'):gmatch('(.-)\n') do
    local letters = chars(line)
    if #letters == 0 then out[#out + 1] = '' end
    for start = 1, #letters, wrapCols do
      local part = {}
      for i = start, math.min(start + wrapCols - 1, #letters) do part[#part + 1] = letters[i] end
      out[#out + 1] = table.concat(part)
    end
  end
  return out
end

function Draw()
  local lines = wrapped[active] or { '' }
  local maximum = math.max(0, #lines - visible)
  offsets[active] = math.max(0, math.min(maximum, offsets[active]))
  local body = {}
  for i = offsets[active] + 1, math.min(#lines, offsets[active] + visible) do body[#body + 1] = lines[i] end
  local content = table.concat(body, '\n')
  if (cache[active] or '') == '' then
    content = string.format('NOTE %02d IS EMPTY - CLICK AND TYPE - ENTER SAVES', active)
  end
  SKIN:Bang('!SetOption', 'NoteBody', 'Text', content)
  SKIN:Bang('!SetOption', 'MemoPage', 'Text', string.format('NOTE %02d OF 03 - %d LINE%s', active, #lines, #lines == 1 and '' or 'S'))
  for i = 1, 3 do
    SKIN:Bang('!SetOption', 'Tab' .. i, 'FontColor',
      SKIN:GetVariable(i == active and 'TextC' or 'DimC'))
    SKIN:Bang('!UpdateMeter', 'Tab' .. i)
  end
  local W = tonumber(SKIN:GetVariable('MemoW')) or 660
  local H = tonumber(SKIN:GetVariable('MemoH')) or 250
  local bodyH = H - 98
  visible = math.max(4, math.floor((bodyH - 4) / 15))
  local x = 20 + (active - 1) * tabPitch
  SKIN:Bang('!SetOption', 'TabUnderline', 'Shape',
    'Line ' .. x .. ',50,' .. (x + tabW) .. ',50 | Stroke Color ' ..
    SKIN:GetVariable('Accent') .. ',208 | StrokeWidth 2')
  local track = bodyH
  local thumb = #lines <= visible and track or math.max(18, track * visible / #lines)
  local y = 52 + (maximum > 0 and offsets[active] / maximum * (track - thumb) or 0)
  SKIN:Bang('!SetOption', 'ScrollThumb', 'Shape',
    string.format('Rectangle %d,%.1f,3,%.1f,1 | Fill Color %s,170 | StrokeWidth 0',
      W - 17, y, thumb, SKIN:GetVariable('Accent')))
  SKIN:Bang('!UpdateMeter', '*')
  SKIN:Bang('!Redraw')
end

function Select(index)
  active = math.max(1, math.min(3, tonumber(index) or 1))
  offsets[active] = 0
  Draw()
end

function Scroll(delta)
  offsets[active] = offsets[active] + tonumber(delta)
  Draw()
end

function Edit()
  SKIN:Bang('!SetOption', 'MemoInput', 'DefaultValue', cache[active] or '')
  SKIN:Bang('!CommandMeasure', 'MemoInput', 'ExecuteBatch 1')
end

function Commit()
  local v = SKIN:GetVariable('MemoTyped') or ''
  if v ~= '' and v ~= (cache[active] or '') then
    local f = io.open(SKIN:GetVariable('@') .. 'Data\\memo' .. active .. '.txt', 'wb')
    if f then f:write(v); f:close() end
  end
  Update()
end


function Update()
  local changed = false
  for i = 1, 3 do
    local f = io.open(SKIN:GetVariable('@') .. 'Data\\memo' .. i .. '.txt', 'rb')
    local s = ''
    if f then s = f:read('*a'):gsub('^\239\187\191', ''); f:close() end
    if cache[i] ~= s then cache[i] = s; wrapped[i] = wrap(s); changed = true end
  end
  if changed then Draw() end
  return active
end

function OnDismiss()
  -- input dismissed by clicking outside (FocusDismiss=1): just redraw
  Draw()
end
