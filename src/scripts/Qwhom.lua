agnosticdb = agnosticdb or {}

agnosticdb.qwhom = agnosticdb.qwhom or {}

local function normalize_name(name)
  if agnosticdb.db and agnosticdb.db.normalize_name then
    return agnosticdb.db.normalize_name(name)
  end
  if type(name) ~= "string" or name == "" then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function trim(value)
  if type(value) ~= "string" then return "" end
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function resolve_area(where)
  if where == "" then
    return "Unknown Area"
  end
  if not mmp or type(mmp.searchRoomExact) ~= "function" or type(mmp.getAreaName) ~= "function" then
    return "Unknown Area"
  end
  local room = mmp.searchRoomExact(where)
  if room and next(room) then
    local area = mmp.getAreaName(next(room))
    if type(area) == "string" and area ~= "" then
      return area
    end
  end
  return "Unknown Area"
end

local function sorted_keys(tbl)
  local keys = {}
  for key in pairs(tbl or {}) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  return keys
end

local function format_names(list)
  table.sort(list, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  local parts = {}
  for _, entry in ipairs(list) do
    if entry.color and entry.color ~= "" then
      parts[#parts + 1] = string.format("<%s>%s<ansi_yellow>", entry.color, entry.name)
    else
      parts[#parts + 1] = entry.name
    end
  end
  return table.concat(parts, "<white>,<ansi_yellow> ")
end

local function filter_ok(area)
  local filter = agnosticdb.qwhom.filter
  if not filter or filter == "" then return true end
  return area:lower():find(filter, 1, true) ~= nil
end

function agnosticdb.qwhom.start(filter)
  agnosticdb.qwhom.data = {}
  agnosticdb.qwhom.active = true
  agnosticdb.qwhom.filter = nil

  if type(filter) == "string" and #trim(filter) > 1 then
    agnosticdb.qwhom.filter = trim(filter):lower()
  end

  if type(enableTrigger) == "function" then
    enableTrigger("ADB Qwhom Capture")
    enableTrigger("ADB Qwhom Display")
  end

  if type(send) == "function" then
    send("config pagelength 250")
    send("queue add free who b")
  end
end

function agnosticdb.qwhom.capture_line(who_raw, where_raw)
  if not agnosticdb.qwhom.active then return end
  if type(deleteFull) == "function" then
    deleteFull()
  end

  local who = trim(who_raw)
  if who == "" then return end
  local lower = who:lower()
  if lower:find("^total:") or lower:find("^name") or lower:find("^%-%-") then
    return
  end

  local where = trim(where_raw)
  local area = ""
  if where == "" then
    where = "Gemmed or Off-Plane"
    area = "Unknown Area"
  else
    area = resolve_area(where)
  end

  local normalized = normalize_name(who) or who
  local color
  if agnosticdb.getCityColor then
    color = agnosticdb.getCityColor(normalized)
  end

  agnosticdb.qwhom.data = agnosticdb.qwhom.data or {}
  agnosticdb.qwhom.data[area] = agnosticdb.qwhom.data[area] or {}
  agnosticdb.qwhom.data[area][where] = agnosticdb.qwhom.data[area][where] or {}
  table.insert(agnosticdb.qwhom.data[area][where], { name = normalized, color = color })
end

function agnosticdb.qwhom.finish()
  if not agnosticdb.qwhom.active then return end
  agnosticdb.qwhom.active = false

  if type(disableTrigger) == "function" then
    disableTrigger("ADB Qwhom Capture")
    disableTrigger("ADB Qwhom Display")
  end

  if type(deleteLine) == "function" then
    deleteLine()
  end

  local data = agnosticdb.qwhom.data or {}
  local area_keys = sorted_keys(data)
  for _, area in ipairs(area_keys) do
    local area_data = data[area] or {}
    if filter_ok(area) then
      local where_keys = sorted_keys(area_data)
      if #where_keys > 0 then
        cecho(string.format("\n<ansi_yellow>[<DodgerBlue>%s<ansi_yellow>]: ", area))
        for _, where in ipairs(where_keys) do
          local where_data = area_data[where] or {}
          local names = format_names(where_data)
          cecho(string.format("\n\t<ansi_yellow>[<linen>%s<ansi_yellow>] (<white>%d<ansi_yellow>): %s", where, #where_data, names))
          if mmp and type(mmp.locateAndEchoSide) == "function" and where ~= "Gemmed or Off-Plane" then
            mmp.locateAndEchoSide(where)
          end
        end
      end
    end
  end

  cecho("\n")
  if type(send) == "function" then
    send("config pagelength 40")
  end

  agnosticdb.qwhom.data = {}
  agnosticdb.qwhom.filter = nil
end
