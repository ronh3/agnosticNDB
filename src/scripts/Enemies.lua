agnosticdb = agnosticdb or {}

agnosticdb.enemies = agnosticdb.enemies or {}

local function prefix()
  return "<cyan>[agnosticdb]<reset> "
end

local function needs_leading_newline()
  if type(line) ~= "string" or line == "" then return false end
  if agnosticdb._echo_line_pending then return false end
  agnosticdb._echo_line_pending = true
  if type(tempTimer) == "function" then
    tempTimer(0, function() agnosticdb._echo_line_pending = false end)
  else
    agnosticdb._echo_line_pending = false
  end
  return true
end

local function echo_line(text)
  local lead = needs_leading_newline() and "\n" or ""
  cecho(lead .. prefix() .. text .. "\n")
end

local function ensure_db_ready()
  if agnosticdb.db and agnosticdb.db.people then return true end
  if agnosticdb.db and agnosticdb.db.init then
    agnosticdb.db.init()
  end
  return agnosticdb.db and agnosticdb.db.people ~= nil
end

local function normalize_org(value)
  if type(value) ~= "string" then return "" end
  local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
  if trimmed == "" then return "" end
  return trimmed:gsub("(%a)([%w']*)", function(a, b)
    return a:upper() .. b:lower()
  end)
end

local function normalize_person_name(name)
  if agnosticdb.db and agnosticdb.db.normalize_name then
    return agnosticdb.db.normalize_name(name)
  end
  if type(name) ~= "string" or name == "" then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function parse_names_into(names, text)
  if type(text) ~= "string" then return end
  local trimmed = text:gsub("%s+$", "")
  if trimmed == "" then return end

  local lower = trimmed:lower()
  if lower == "none" or lower == "none." then return end
  if lower:find("^total:") then return end

  for chunk in trimmed:gmatch("([^,]+)") do
    local name = chunk:gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("^and%s+", "")
    name = name:gsub("%.$", "")
    if name ~= "" then
      local normalized = normalize_person_name(name)
      if normalized then
        names[normalized] = true
      end
    end
  end
end

local function count_names(names)
  local count = 0
  for _ in pairs(names) do
    count = count + 1
  end
  return count
end

local function apply_city_list(city, names)
  if not ensure_db_ready() then
    return nil, nil, "db_unavailable"
  end

  local normalized_city = normalize_org(city)
  if normalized_city == "" then
    echo_line("City enemies capture missing city name.")
    return 0, 0
  end

  local current = {}
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.enemy_city, normalized_city))
  if rows then
    for _, row in ipairs(rows) do
      if row.name and row.name ~= "" then
        current[row.name] = true
      end
    end
  end

  local cleared = 0
  for name in pairs(current) do
    if not names[name] then
      agnosticdb.db.upsert_person({ name = name, enemy_city = "" })
      cleared = cleared + 1
    end
  end

  local updated = 0
  for name in pairs(names) do
    agnosticdb.db.upsert_person({ name = name, enemy_city = normalized_city })
    updated = updated + 1
  end

  return updated, cleared
end

local function apply_personal_list(names)
  if not ensure_db_ready() then
    return nil, nil, "db_unavailable"
  end

  local current = {}
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.iff, "enemy"))
  if rows then
    for _, row in ipairs(rows) do
      if row.name and row.name ~= "" then
        current[row.name] = true
      end
    end
  end

  local cleared = 0
  for name in pairs(current) do
    if not names[name] then
      agnosticdb.db.upsert_person({ name = name, iff = "auto" })
      cleared = cleared + 1
    end
  end

  local updated = 0
  for name in pairs(names) do
    agnosticdb.db.upsert_person({ name = name, iff = "enemy" })
    updated = updated + 1
  end

  return updated, cleared
end

local function refresh_highlights()
  if agnosticdb.highlights and agnosticdb.highlights.reload then
    agnosticdb.highlights.reload()
  end
end

local function apply_house_list(house, names)
  if not ensure_db_ready() then
    return nil, nil, "db_unavailable"
  end

  local normalized_house = normalize_org(house)
  if normalized_house == "" then
    echo_line("House enemies capture missing house name.")
    return 0, 0
  end

  local current = {}
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.enemy_house, normalized_house))
  if rows then
    for _, row in ipairs(rows) do
      if row.name and row.name ~= "" then
        current[row.name] = true
      end
    end
  end

  local cleared = 0
  for name in pairs(current) do
    if not names[name] then
      agnosticdb.db.upsert_person({ name = name, enemy_house = "" })
      cleared = cleared + 1
    end
  end

  local updated = 0
  for name in pairs(names) do
    agnosticdb.db.upsert_person({ name = name, enemy_house = normalized_house })
    updated = updated + 1
  end

  return updated, cleared
end

function agnosticdb.enemies.abort_capture()
  local capture = agnosticdb.enemies.capture
  if not capture then return end
  if capture.line_trigger then killTrigger(capture.line_trigger) end
  if capture.prompt_trigger then killTrigger(capture.prompt_trigger) end
  agnosticdb.enemies.capture = nil
end

function agnosticdb.enemies.finish_capture()
  local capture = agnosticdb.enemies.capture
  if not capture then return end
  if capture.line_trigger then killTrigger(capture.line_trigger) end
  if capture.prompt_trigger then killTrigger(capture.prompt_trigger) end
  agnosticdb.enemies.capture = nil

  local names = capture.names or {}
  if capture.kind == "city" then
    local updated, cleared, err = apply_city_list(capture.org, names)
    if err == "db_unavailable" then
      echo_line("City enemies update skipped; database not ready.")
      return
    end
    local total = count_names(names)
    echo_line(string.format("City enemies updated for %s: %d listed, %d set, %d cleared.", capture.org, total, updated, cleared))
  elseif capture.kind == "house" then
    local updated, cleared, err = apply_house_list(capture.org, names)
    if err == "db_unavailable" then
      echo_line("House enemies update skipped; database not ready.")
      return
    end
    local total = count_names(names)
    echo_line(string.format("House enemies updated for %s: %d listed, %d set, %d cleared.", capture.org, total, updated, cleared))
  elseif capture.kind == "personal" then
    local updated, cleared, err = apply_personal_list(names)
    if err == "db_unavailable" then
      echo_line("Personal enemies update skipped; database not ready.")
      return
    end
    local total = count_names(names)
    echo_line(string.format("Personal enemies updated: %d listed, %d set, %d cleared.", total, updated, cleared))
    refresh_highlights()
  end
end

function agnosticdb.enemies.capture_city(city)
  local org = normalize_org(city)
  if org == "" then
    echo_line("City enemies capture missing city name.")
    return
  end

  agnosticdb.enemies.abort_capture()
  local capture = {
    kind = "city",
    org = org,
    names = {}
  }
  agnosticdb.enemies.capture = capture

  if type(tempRegexTrigger) ~= "function" then
    echo_line("Mudlet temp triggers unavailable; cannot capture city enemies.")
    agnosticdb.enemies.capture = nil
    return
  end

  capture.line_trigger = tempRegexTrigger("^.*$", function()
    local text = line or ""
    if text == "" then return end
    if type(isPrompt) == "function" and isPrompt() then
      agnosticdb.enemies.finish_capture()
      return
    end
    if text:find("^Total:%s*%d+") then
      agnosticdb.enemies.finish_capture()
      return
    end
    parse_names_into(capture.names, text)
  end)

  if type(tempPromptTrigger) == "function" then
    capture.prompt_trigger = tempPromptTrigger(function()
      agnosticdb.enemies.finish_capture()
    end)
  end

  echo_line(string.format("Capturing city enemies for %s...", org))
end

function agnosticdb.enemies.capture_personal()
  agnosticdb.enemies.abort_capture()
  local capture = {
    kind = "personal",
    names = {}
  }
  agnosticdb.enemies.capture = capture

  if type(tempRegexTrigger) ~= "function" then
    echo_line("Mudlet temp triggers unavailable; cannot capture personal enemies.")
    agnosticdb.enemies.capture = nil
    return
  end

  capture.line_trigger = tempRegexTrigger("^.*$", function()
    local text = line or ""
    if text == "" then return end
    if type(isPrompt) == "function" and isPrompt() then
      agnosticdb.enemies.finish_capture()
      return
    end
    if text:find("^You have currently used") then
      agnosticdb.enemies.finish_capture()
      return
    end
    parse_names_into(capture.names, text)
  end)

  if type(tempPromptTrigger) == "function" then
    capture.prompt_trigger = tempPromptTrigger(function()
      agnosticdb.enemies.finish_capture()
    end)
  end

  echo_line("Capturing personal enemies...")
end

function agnosticdb.enemies.set_personal(name, is_enemy)
  if not ensure_db_ready() then
    echo_line("Personal enemies update skipped; database not ready.")
    return
  end
  local normalized = normalize_person_name(name)
  if not normalized then return end

  if is_enemy then
    agnosticdb.db.upsert_person({ name = normalized, iff = "enemy" })
  else
    local person = agnosticdb.db.get_person(normalized)
    if person and person.iff == "enemy" then
      agnosticdb.db.upsert_person({ name = normalized, iff = "auto" })
    end
  end

  refresh_highlights()
end

function agnosticdb.enemies.clear_personal()
  if not ensure_db_ready() then
    echo_line("Personal enemies update skipped; database not ready.")
    return
  end
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.iff, "enemy"))
  local cleared = 0
  if rows then
    for _, row in ipairs(rows) do
      if row.name and row.name ~= "" then
        agnosticdb.db.upsert_person({ name = row.name, iff = "auto" })
        cleared = cleared + 1
      end
    end
  end
  echo_line(string.format("Personal enemies cleared: %d.", cleared))
  refresh_highlights()
end

function agnosticdb.enemies.capture_house(house)
  local org = normalize_org(house)
  if org == "" then
    echo_line("House enemies capture missing house name.")
    return
  end

  agnosticdb.enemies.abort_capture()
  local capture = {
    kind = "house",
    org = org,
    names = {}
  }
  agnosticdb.enemies.capture = capture

  if type(tempRegexTrigger) ~= "function" then
    echo_line("Mudlet temp triggers unavailable; cannot capture house enemies.")
    agnosticdb.enemies.capture = nil
    return
  end

  capture.line_trigger = tempRegexTrigger("^.*$", function()
    local text = line or ""
    if text == "" then return end
    if type(isPrompt) == "function" and isPrompt() then
      agnosticdb.enemies.finish_capture()
      return
    end
    if text:find("^Total:%s*%d+") then
      agnosticdb.enemies.finish_capture()
      return
    end
    parse_names_into(capture.names, text)
  end)

  if type(tempPromptTrigger) == "function" then
    capture.prompt_trigger = tempPromptTrigger(function()
      agnosticdb.enemies.finish_capture()
    end)
  end

  echo_line(string.format("Capturing house enemies for %s...", org))
end
