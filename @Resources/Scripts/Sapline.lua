-- Sapline.lua - agenda as one horizontal strand ("Sapline").
-- Done events dim leftward, the next event is the brightest point,
-- and the NOW marker slides forward along the strand.
-- FUTURE EVENTS: type a date prefix in the add box -
--   "mm/dd title"      e.g. 11/05 dentist
--   "mm/dd/yy title"   e.g. 11/05/26 dentist
--   "+N title"         e.g. +3 dentist (N days from today)
--   "tomorrow title"   e.g. tomorrow dentist
--   "hh:mm title"      today at a time (existing behavior)
--   "title"            today, no time (existing behavior)
-- Optional time after the date: "11/05 14:30 dentist".
-- Upcoming (future-dated) events render in the rows under the strand.
-- Data: @Resources\Data\agenda.csv  (date,start,end,title)

local padX = 76
local strandY = 96
local maxDots = 7
local upRows = 3

local function csvSplit(line)
  local fields, cell, quoted, i = {}, '', false, 1
  while i <= #line do
    local c = line:sub(i, i)
    if c == '"' then
      if quoted and line:sub(i + 1, i + 1) == '"' then cell = cell .. '"'; i = i + 1
      else quoted = not quoted end
    elseif c == ',' and not quoted then fields[#fields + 1] = cell; cell = ''
    else cell = cell .. c end
    i = i + 1
  end
  fields[#fields + 1] = cell
  return fields
end

local function minutes(s)
  if not s then return nil end
  local h, m = s:match('^(%d?%d):(%d%d)$')
  if h then return tonumber(h) * 60 + tonumber(m) end
  return nil
end

local function trim(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end

local function csvCell(s)
  s = trim(s)
  if s:find('[",]') then s = '"' .. s:gsub('"', '""') .. '"' end
  return s
end

local function parseDate(s)
  -- accepts mm/dd/yy or mm/dd/yyyy, returns epoch (noon) or nil
  local m, d, y = s:match('^(%d%d?)/(%d%d?)/(%d%d?%d?%d?)$')
  if not m then return nil end
  m, d, y = tonumber(m), tonumber(d), tonumber(y)
  if y < 100 then y = y + 2000 end
  if m < 1 or m > 12 or d < 1 or d > 31 then return nil end
  return os.time({ year = y, month = m, day = d, hour = 12 })
end

local function midnight(t)
  return os.time({ year = t.year, month = t.month, day = t.day, hour = 0 })
end

function Initialize()
  W = tonumber(SKIN:GetVariable('AgendaW')) or 883
  H = tonumber(SKIN:GetVariable('AgendaH')) or 200
  SKIN:Bang('!SetOption', 'Strand', 'Shape',
    'Line ' .. padX .. ',' .. strandY .. ',' .. (W - padX) .. ',' .. strandY ..
    ' | Stroke Color ' .. SKIN:GetVariable('LineC') .. ',255 | StrokeWidth 2')
  SKIN:Bang('!SetOption', 'Strand', 'Shape2',
    'Line ' .. padX .. ',' .. strandY .. ',' .. (W - padX) .. ',' .. strandY ..
    ' | Stroke Color ' .. SKIN:GetVariable('Accent') .. ',26 | StrokeWidth 7')
  -- right-click delete hints on every interactive entry meter
  for i = 1, maxDots do
    SKIN:Bang('!SetOption', 'Dot' .. i, 'ToolTipText', 'Right-click to delete this entry')
    SKIN:Bang('!SetOption', 'Label' .. i, 'ToolTipText', 'Right-click to delete this entry')
  end
  for r = 1, upRows do
    SKIN:Bang('!SetOption', 'Up' .. r, 'ToolTipText', 'Right-click to delete this entry')
  end
end

function Update()
  local path = SKIN:GetVariable('@') .. 'Data\\agenda.csv'
  local f = io.open(path, 'r')
  local today = os.date('%m/%d/%y')
  local today0 = midnight(os.date('*t'))
  local nowMin = os.date('%H') * 60 + os.date('%M')
  local events = {}
  local upcoming = {}

  if f then
    local first = true
    local rowNum = 0 -- 1-based CSV line number (header = 1), for delete
    for line in f:lines() do
      rowNum = rowNum + 1
      if first then first = false
      else
        local p = csvSplit(line)
        if #p >= 4 and trim(p[1]) ~= '' then
          local dv = parseDate(trim(p[1]))
          if dv then
            local s = minutes(trim(p[2]))
            local e = minutes(trim(p[3]))
            local title = trim(p[4])
            if title ~= '' then
              -- compare calendar DAY (parseDate returns noon, which is
              -- later than midnight of the same day)
              local dayKey = os.date('%Y%m%d', dv)
              local todayKey = os.date('%Y%m%d', today0)
              if dayKey < todayKey then
                -- past: ignore
              elseif dayKey == todayKey then
                -- -1 marks "no time set": resolved below so no-time
                -- tasks line up consecutively instead of all piling
                -- onto the NOW marker
                events[#events + 1] = { s = s or -1, e = e or (s or -1), seq = #events + 1, row = rowNum, t = title }
              else
                upcoming[#upcoming + 1] = { dv = dv, s = s, row = rowNum, t = title }
              end
            end
          end
        end
      end
    end
    f:close()
  end

  -- resolve no-time tasks AFTER reading the file: first one sits at
  -- the current minute, each following one 45 minutes later (clamped
  -- to the end of the day) - they stay consecutive in the order they
  -- were added and ride just ahead of NOW
  local noTimeStep = 45
  local noTimeIdx = 0
  for _, ev in ipairs(events) do
    if ev.s == -1 then
      noTimeIdx = noTimeIdx + 1
      ev.s = math.min(nowMin + noTimeIdx * noTimeStep, 1439)
      if ev.e == -1 then ev.e = ev.s end
    end
  end
  table.sort(events, function(a, b)
    if a.s ~= b.s then return a.s < b.s end
    return (a.seq or 0) < (b.seq or 0)
  end)
  table.sort(upcoming, function(a, b)
    if a.dv ~= b.dv then return a.dv < b.dv end
    return (a.s or 9999) < (b.s or 9999)
  end)

  SKIN:Bang('!SetOption', 'DateTag', 'Text', os.date('%A - %B %d'))
  SKIN:Bang('!SetOption', 'DateTag', 'W', 200)
  SKIN:Bang('!SetOption', 'DateTag', 'X', W - 222)

  local n = #events
  if n == 0 then
    SKIN:Bang('!SetOption', 'Empty', 'Hidden', 0)
    SKIN:Bang('!SetOption', 'CountText', 'Text', 'NO EVENTS TODAY')
    for i = 1, maxDots do
      SKIN:Bang('!SetOption', 'Dot' .. i, 'Hidden', 1)
      SKIN:Bang('!SetOption', 'Label' .. i, 'Hidden', 1)
    end
    SKIN:Bang('!SetOption', 'NowTick', 'Hidden', 1)
    SKIN:Bang('!SetOption', 'NowText', 'Hidden', 1)
  else
    SKIN:Bang('!SetOption', 'Empty', 'Hidden', 1)
    local span = W - padX * 2
    local nextIdx = 0
    for i, ev in ipairs(events) do
      if ev.e >= nowMin and nextIdx == 0 then nextIdx = i end
    end
    local done = 0
    local shown = math.min(n, maxDots)
    -- Events with no time all sit at "now", so they (and any events
    -- sharing the same hh:mm) map to the same x and stack. Group
    -- near-identical positions into clusters, then fan each cluster
    -- out: dots spread horizontally on the strand, labels stack into
    -- lanes above it so nothing overlaps.
    local rawX = {}
    for i = 1, shown do
      rawX[i] = padX + math.floor(math.min(events[i].s, 1439) / 1440 * span)
    end
    local clusters, ci = {}, 0
    for i = 1, shown do
      if ci == 0 or rawX[i] - clusters[ci].x > 18 then
        ci = ci + 1
        clusters[ci] = { x = rawX[i], members = {} }
      end
      clusters[ci].members[#clusters[ci].members + 1] = i
    end
    for _, cl in ipairs(clusters) do
      local k = #cl.members
      for j, i in ipairs(cl.members) do
        local ev = events[i]
        local isDone = ev.e < nowMin
        local isNext = (i == nextIdx)
        if isDone then done = done + 1 end
        local col = isDone and SKIN:GetVariable('DimC') or SKIN:GetVariable('Accent')
        -- fan dots horizontally inside the cluster (centered on the
        -- cluster's original position)
        local dx = k > 1 and math.floor((j - (k + 1) / 2) * 16) or 0
        local x = math.max(padX, math.min(W - padX, rawX[i] + dx))
        -- labels: lane 0 on the normal row, collisions move up one
        -- lane (13px) at a time, capped so they stay clear of the header
        local lane = math.min(j - 1, 3)
        local ly = 70 - lane * 13
        if isNext then
          -- outer halo ring + solid inner dot (two shapes - a second
          -- Ellipse cannot be a modifier of the first, that is invalid)
          SKIN:Bang('!SetOption', 'Dot' .. i, 'Shape',
            'Ellipse ' .. x .. ',' .. strandY .. ',11 | Fill Color 0,0,0,1 | Stroke Color ' .. col .. ',70 | StrokeWidth 5')
          SKIN:Bang('!SetOption', 'Dot' .. i, 'Shape2',
            'Ellipse ' .. x .. ',' .. strandY .. ',5 | Fill Color ' .. col .. ',255 | StrokeWidth 0')
        else
          SKIN:Bang('!SetOption', 'Dot' .. i, 'Shape',
            'Ellipse ' .. x .. ',' .. strandY .. ',4 | Fill Color ' .. col .. ',' .. (isDone and 60 or 150) .. ' | StrokeWidth 0')
          SKIN:Bang('!SetOption', 'Dot' .. i, 'Shape2',
            'Rectangle -100,-100,1,1 | Fill Color 0,0,0,1 | StrokeWidth 0')
        end
        SKIN:Bang('!SetOption', 'Dot' .. i, 'Hidden', 0)
        local label = ev.t
        if #label > 24 then label = label:sub(1, 23) .. '...' end
        local lx = math.max(padX + 60, math.min(W - padX - 60, x))
        SKIN:Bang('!SetOption', 'Label' .. i, 'Text', label)
        SKIN:Bang('!SetOption', 'Label' .. i, 'X', lx)
        SKIN:Bang('!SetOption', 'Label' .. i, 'Y', ly)
        SKIN:Bang('!SetOption', 'Label' .. i, 'FontColor', col .. ',' .. (isDone and 80 or (isNext and 255 or 170)))
        SKIN:Bang('!SetOption', 'Label' .. i, 'FontSize', isNext and 10 or 9)
        SKIN:Bang('!SetOption', 'Label' .. i, 'Hidden', 0)
        -- right-click either the dot or its label to delete this entry
        local delAction = '[!CommandMeasure Logic "Delete(' .. ev.row .. ')"]'
        SKIN:Bang('!SetOption', 'Dot' .. i, 'RightMouseUpAction', delAction)
        SKIN:Bang('!SetOption', 'Label' .. i, 'RightMouseUpAction', delAction)
      end
    end
    for i = shown + 1, maxDots do
      SKIN:Bang('!SetOption', 'Dot' .. i, 'Hidden', 1)
      SKIN:Bang('!SetOption', 'Label' .. i, 'Hidden', 1)
    end
    if n > maxDots then
      SKIN:Bang('!SetOption', 'CountText', 'Text', (n - maxDots) .. ' MORE NOT SHOWN')
    else
      SKIN:Bang('!SetOption', 'CountText', 'Text', n .. ' EVENT' .. (n == 1 and '' or 'S') .. (done > 0 and (' - ' .. done .. ' DONE') or ''))
    end
    -- NOW marker
    local nx = padX + math.floor(math.min(nowMin, 1439) / 1440 * span)
    SKIN:Bang('!SetOption', 'NowTick', 'Shape',
      'Line ' .. nx .. ',' .. (strandY - 8) .. ',' .. nx .. ',' .. (strandY + 10) ..
      ' | Stroke Color ' .. SKIN:GetVariable('TextC') .. ',220 | StrokeWidth 2')
    SKIN:Bang('!SetOption', 'NowTick', 'Hidden', 0)
    SKIN:Bang('!SetOption', 'NowText', 'X', nx)
    SKIN:Bang('!SetOption', 'NowText', 'Hidden', 0)
  end

  -- UPCOMING rows (future-dated events)
  SKIN:Bang('!SetOption', 'UpcomingTag', 'Text',
    #upcoming > 0 and ('UPCOMING - ' .. #upcoming) or 'UPCOMING')
  SKIN:Bang('!SetOption', 'UpcomingTag', 'Hidden', #upcoming == 0 and 1 or 0)
  for r = 1, upRows do
    local ev = upcoming[r]
    if ev then
      local when = string.upper(os.date('%a %m/%d', ev.dv))
      if ev.s then when = when .. ' ' .. string.format('%02d:%02d', math.floor(ev.s / 60), ev.s % 60) end
      local title = ev.t
      if #title > 38 then title = title:sub(1, 37) .. '...' end
      SKIN:Bang('!SetOption', 'Up' .. r, 'Text', when .. '  -  ' .. string.upper(title))
      SKIN:Bang('!SetOption', 'Up' .. r, 'FontColor',
        (r == 1 and SKIN:GetVariable('Accent3') or SKIN:GetVariable('DimC')) .. (r == 1 and ',235' or ',190'))
      SKIN:Bang('!SetOption', 'Up' .. r, 'Hidden', 0)
      SKIN:Bang('!SetOption', 'Up' .. r, 'RightMouseUpAction',
        '[!CommandMeasure Logic "Delete(' .. ev.row .. ')"]')
    else
      SKIN:Bang('!SetOption', 'Up' .. r, 'Hidden', 1)
    end
  end

  SKIN:Bang('!UpdateMeter', '*')
  SKIN:Bang('!Redraw')
end

function Delete(row)
  -- remove one CSV line (row 1 is the header, never delete it),
  -- rewrite the file and redraw
  row = tonumber(row)
  if not row or row < 2 then return end
  local path = SKIN:GetVariable('@') .. 'Data\\agenda.csv'
  local f = io.open(path, 'r')
  if not f then return end
  local keep, i = {}, 0
  for line in f:lines() do
    i = i + 1
    if i ~= row then keep[#keep + 1] = line end
  end
  f:close()
  local out = io.open(path, 'w')
  if not out then return end
  out:write(table.concat(keep, '\n') .. (#keep > 0 and '\n' or ''))
  out:close()
  Update()
end

function Add()
  SKIN:Bang('!SetOption', 'AgendaInput', 'DefaultValue', '')
  SKIN:Bang('!CommandMeasure', 'AgendaInput', 'ExecuteBatch 1')
end

function Commit()
  local v = trim(SKIN:GetVariable('TypedText') or '')
  if v == '' then return end

  local dateStr, startT, rest

  -- mm/dd/yy title  (2-digit or 4-digit year)
  local mm, dd, yy, r = v:match('^(%d%d?)/(%d%d?)/(%d%d?%d?%d?)%s+(.+)$')
  if mm then
    local dv = parseDate(mm .. '/' .. dd .. '/' .. yy)
    if dv then
      dateStr = os.date('%m/%d/%y', dv)
      rest = r
    end
  end

  -- mm/dd title (assumes current year; rolls to next year if already past)
  if not dateStr and not rest then
    local m2, d2, r2 = v:match('^(%d%d?)/(%d%d?)%s+(.+)$')
    if m2 and tonumber(m2) <= 12 and tonumber(d2) <= 31 then
      local t = os.date('*t')
      local dv = os.time({ year = t.year, month = tonumber(m2), day = tonumber(d2), hour = 12 })
      if dv < midnight(t) then dv = dv + 31622400 end -- roughly +1 year
      dateStr = os.date('%m/%d/%y', dv)
      rest = r2
    end
  end

  -- +N title (N days from today)
  if not dateStr and not rest then
    local nn, r2 = v:match('^%+(%d+)%s+(.+)$')
    if nn then
      dateStr = os.date('%m/%d/%y', os.time() + tonumber(nn) * 86400)
      rest = r2
    end
  end

  -- tomorrow title
  if not dateStr and not rest then
    local r2 = v:match('^tomorrow%s+(.+)$')
    if r2 then
      dateStr = os.date('%m/%d/%y', os.time() + 86400)
      rest = r2
    end
  end

  -- hh:mm title (today, existing behavior)
  if not dateStr and not rest then
    local tt, r2 = v:match('^(%d?%d:%d%d)%s+(.+)$')
    if tt then startT = tt; rest = r2 end
  end

  -- plain title = today, no time
  if not rest then rest = v end

  -- optional time after a date prefix: "11/05 14:30 dentist"
  if dateStr and not startT then
    local tt, r2 = rest:match('^(%d?%d:%d%d)%s+(.+)$')
    if tt then startT = tt; rest = r2 end
  end

  local path = SKIN:GetVariable('@') .. 'Data\\agenda.csv'
  local f = io.open(path, 'a')
  if f then
    f:write('\n' .. (dateStr or os.date('%m/%d/%y')) .. ',' .. (startT or '') .. ',,' .. csvCell(rest))
    f:close()
  end
  Update()
end

function OnDismiss()
  -- input dismissed by clicking outside (FocusDismiss=1): just restore
  SKIN:Bang('!Redraw')
end
