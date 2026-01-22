agnosticdb = agnosticdb or {}

agnosticdb.lists = agnosticdb.lists or {}

local function prefix()
  return "<cyan>[agnosticdb]<reset> "
end

local function echo_line(text)
  cecho(prefix() .. text .. "\n")
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

local function titlecase_words(value)
  if type(value) ~= "string" then return "" end
  if value == "" then return "" end
  return value:gsub("(%a)([%w']*)", function(a, b)
    return a:upper() .. b:lower()
  end)
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

local function split_columns(text)
  local cols = {}
  local remaining = text
  while true do
    local s, e = remaining:find("%s%s+")
    if not s then
      local tail = remaining:gsub("%s+$", "")
      if tail ~= "" then
        cols[#cols + 1] = tail
      end
      break
    end
    local part = remaining:sub(1, s - 1):gsub("%s+$", "")
    if part ~= "" then
      cols[#cols + 1] = part
    end
    remaining = remaining:sub(e + 1)
  end
  return cols
end

local function extract_name(raw, known)
  if type(raw) ~= "string" then return nil end
  local trimmed = raw:gsub("%s+$", "")
  if trimmed == "" then return nil end

  local before_comma = trimmed:match("^(.-),")
  local base = before_comma or trimmed
  local words = {}
  for word in base:gmatch("[%a']+") do
    words[#words + 1] = word
  end

  local match
  local known_set = type(known) == "table" and known or nil
  if known_set then
    for _, word in ipairs(words) do
      local normalized = normalize_person_name(word)
      if normalized and known_set[normalized] then
        if match and match ~= normalized then
          return nil
        end
        match = normalized
      end
    end
  end

  if match then return match end

  if known_set then
    return nil
  end

  if #words == 1 then
    return normalize_person_name(words[1])
  end
  if #words == 2 then
    return normalize_person_name(words[2])
  end

  return nil
end

local function build_known_set()
  local known = {}
  if agnosticdb.db and agnosticdb.db.safe_fetch and agnosticdb.db.people then
    local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
    if rows then
      for _, row in ipairs(rows) do
        if row.name and row.name ~= "" then
          known[row.name] = true
        end
      end
    end
  end

  if agnosticdb.api and type(agnosticdb.api.last_list_names) == "table" then
    for _, name in ipairs(agnosticdb.api.last_list_names) do
      local normalized = normalize_person_name(name)
      if normalized then
        known[normalized] = true
      end
    end
  end

  local count = 0
  for _ in pairs(known) do
    count = count + 1
  end

  if count == 0 then
    return nil
  end

  return known
end

local function apply_citizens_list(city, names)
  if not ensure_db_ready() then
    return nil, "db_unavailable"
  end

  local normalized_city = normalize_org(city)
  if normalized_city == "" then
    echo_line("Citizens list missing city name.")
    return 0
  end

  local updated = 0
  for name in pairs(names) do
    local record = { name = name, city = normalized_city }
    local existing = agnosticdb.db.get_person(name)
    if not existing or existing.source == "" then
      record.source = "citizens_list"
    end
    agnosticdb.db.upsert_person(record)
    updated = updated + 1
  end

  return updated
end

local function parse_table_line(capture, text)
  if text == "" then return end
  if text:find("^%s*$") then return end
  if text:find("^%s*%-+%s*$") then return end
  if text:find("^Citizen%s+") or text:find("^Member%s+") then return end

  local cols = split_columns(text)
  if #cols < 2 then return end

  local name_raw = cols[1]
  local class_raw = cols[#cols]
  if class_raw == "" or class_raw == "Class" then return end

  if not ensure_db_ready() then
    capture.skipped = capture.skipped + 1
    return
  end

  local name = extract_name(name_raw, capture.known)
  if not name then
    capture.skipped = capture.skipped + 1
    return
  end

  local class = titlecase_words(class_raw)
  agnosticdb.db.upsert_person({ name = name, class = class })
  capture.updated = capture.updated + 1
end

function agnosticdb.lists.abort_capture()
  local capture = agnosticdb.lists.capture
  if not capture then return end
  if capture.line_trigger then killTrigger(capture.line_trigger) end
  if capture.prompt_trigger then killTrigger(capture.prompt_trigger) end
  agnosticdb.lists.capture = nil
end

function agnosticdb.lists.finish_capture()
  local capture = agnosticdb.lists.capture
  if not capture then return end
  if capture.line_trigger then killTrigger(capture.line_trigger) end
  if capture.prompt_trigger then killTrigger(capture.prompt_trigger) end
  agnosticdb.lists.capture = nil

  if capture.kind == "citizens_list" then
    local updated, err = apply_citizens_list(capture.city, capture.names or {})
    if err == "db_unavailable" then
      echo_line("Citizens list update skipped; database not ready.")
      return
    end
    local total = 0
    for _ in pairs(capture.names or {}) do
      total = total + 1
    end
    echo_line(string.format("Citizens list updated for %s: %d listed, %d set.", capture.city, total, updated))
  elseif capture.kind == "table" then
    echo_line(string.format("List capture (%s) complete: %d updated, %d skipped.", capture.label, capture.updated, capture.skipped))
  end
end

function agnosticdb.lists.capture_citizens_list(city)
  local normalized = normalize_org(city)
  if normalized == "" then
    echo_line("Citizens list missing city name.")
    return
  end

  agnosticdb.lists.abort_capture()
  local capture = {
    kind = "citizens_list",
    city = normalized,
    names = {}
  }
  agnosticdb.lists.capture = capture

  if type(tempRegexTrigger) ~= "function" then
    echo_line("Mudlet temp triggers unavailable; cannot capture citizens list.")
    agnosticdb.lists.capture = nil
    return
  end

  capture.line_trigger = tempRegexTrigger("^.*$", function()
    local text = line or ""
    if text == "" then return end
    if type(isPrompt) == "function" and isPrompt() then
      agnosticdb.lists.finish_capture()
      return
    end
    if text:find("^Total:%s*%d+") then
      agnosticdb.lists.finish_capture()
      return
    end
    parse_names_into(capture.names, text)
  end)

  if type(tempPromptTrigger) == "function" then
    capture.prompt_trigger = tempPromptTrigger(function()
      agnosticdb.lists.finish_capture()
    end)
  end

  echo_line(string.format("Capturing active citizens for %s...", normalized))
end

function agnosticdb.lists.capture_table(label)
  agnosticdb.lists.abort_capture()
  local capture = {
    kind = "table",
    label = label or "who",
    updated = 0,
    skipped = 0,
    known = build_known_set()
  }
  agnosticdb.lists.capture = capture

  if type(tempRegexTrigger) ~= "function" then
    echo_line("Mudlet temp triggers unavailable; cannot capture list table.")
    agnosticdb.lists.capture = nil
    return
  end

  if agnosticdb.api and agnosticdb.api.fetch_list then
    agnosticdb.api.fetch_list(function(names, status)
      if status == "ok" and type(names) == "table" then
        capture.known = build_known_set() or capture.known
      end
    end)
  end

  capture.line_trigger = tempRegexTrigger("^.*$", function()
    local text = line or ""
    if text == "" then return end
    if type(isPrompt) == "function" and isPrompt() then
      agnosticdb.lists.finish_capture()
      return
    end
    parse_table_line(capture, text)
  end)

  if type(tempPromptTrigger) == "function" then
    capture.prompt_trigger = tempPromptTrigger(function()
      agnosticdb.lists.finish_capture()
    end)
  end

  echo_line(string.format("Capturing list table (%s)...", capture.label))
end
