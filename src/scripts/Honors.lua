agnosticdb = agnosticdb or {}

agnosticdb.honors = agnosticdb.honors or {}
agnosticdb.honors.active = agnosticdb.honors.active or nil
agnosticdb.honors.queue = agnosticdb.honors.queue or {}
agnosticdb.honors.queue_running = agnosticdb.honors.queue_running or false
agnosticdb.honors.queue_stats = agnosticdb.honors.queue_stats or nil

local function prefix()
  return "<cyan>[agnosticdb]<reset> "
end

local function echo_line(text)
  cecho(prefix() .. text .. "\n")
end

local function normalize_person_name(name)
  if agnosticdb.db and agnosticdb.db.normalize_name then
    return agnosticdb.db.normalize_name(name)
  end
  if type(name) ~= "string" or name == "" then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function honors_delay_seconds()
  local delay = 2
  if agnosticdb.conf and agnosticdb.conf.honors then
    delay = tonumber(agnosticdb.conf.honors.delay_seconds) or delay
  end
  if delay < 0 then delay = 0 end
  return delay
end

local function titlecase_words(value)
  if type(value) ~= "string" then return "" end
  if value == "" then return "" end
  return value:gsub("(%a)([%w']*)", function(a, b)
    return a:upper() .. b:lower()
  end)
end

local function class_list()
  return {
    "Alchemist",
    "Apostate",
    "Bard",
    "Blademaster",
    "Depthswalker",
    "Druid",
    "Infernal",
    "Jester",
    "Magi",
    "Monk",
    "Occultist",
    "Paladin",
    "Pariah",
    "Priest",
    "Psion",
    "Runewarden",
    "Sentinel",
    "Serpent",
    "Shaman",
    "Sylvan",
    "Unnamable"
  }
end

local function find_class(line)
  if type(line) ~= "string" then return nil end
  local lower = line:lower()
  for _, class in ipairs(class_list()) do
    local pattern = "%f[%a]" .. class:lower() .. "%f[%A]"
    if lower:find(pattern) then
      return class
    end
  end
  local color = line:match("(%a+)%s+Dragon")
  if color then
    return titlecase_words(color) .. " Dragon"
  end
  if lower:find("%f[%a]dragon%f[%A]") then
    return "Dragon"
  end
  return nil
end

local function find_city(line)
  if type(line) ~= "string" then return nil end
  local lower = line:lower()
  for _, city in ipairs(agnosticdb.politics and agnosticdb.politics.cities or {}) do
    local pattern = "%f[%a]" .. city:lower() .. "%f[%A]"
    if lower:find(pattern) then
      return city
    end
  end
  return nil
end

local function find_house(line)
  if type(line) ~= "string" then return nil end
  local match = line:match("House of ([%a%s']+)%p?$")
  if match then
    return titlecase_words(match:gsub("%s+$", ""))
  end
  match = line:match("House ([%a%s']+)%p?$")
  if match then
    return titlecase_words(match:gsub("%s+$", ""))
  end
  local lower = line:lower()
  if lower:find(" in the ") and not lower:find("army of") and not lower:find("city of") then
    match = line:match(" in the ([%a%s']+)%p?$")
    if match then
      local candidate = titlecase_words(match:gsub("%s+$", ""))
      if candidate ~= "" then
        local city = find_city(candidate)
        if not city then
          return candidate
        end
      end
    end
  end
  return nil
end

local function find_race(line)
  if type(line) ~= "string" then return nil end
  local inner = line:match("%(([^)]+)%)")
  if not inner then return nil end
  local trimmed = inner:gsub("^%s+", ""):gsub("%s+$", "")
  if trimmed == "" then return nil end

  local lower = trimmed:lower()
  if lower:find("^male%s+") then
    trimmed = trimmed:sub(6)
  elseif lower:find("^female%s+") then
    trimmed = trimmed:sub(8)
  end

  local race = trimmed:gsub("^%s+", ""):gsub("%s+$", "")
  if race == "" then return nil end

  local race_lower = race:lower()
  if race_lower:find("%f[%a]elemental%f[%A]") then
    return "Elemental"
  end
  if race_lower:find("%f[%a]dragon%f[%A]") then
    return "Dragon"
  end

  return titlecase_words(race)
end

local function find_title(name, line)
  if type(name) ~= "string" or type(line) ~= "string" then return nil end
  local lower = line:lower()
  local name_lower = name:lower()
  if lower:find("%f[%a]" .. name_lower .. "%f[%A]") and line:find(",") then
    return line:gsub("^%s+", ""):gsub("%s+$", "")
  end
  return nil
end

local function parse_ranks(line)
  if type(line) ~= "string" then return nil, nil end
  local lower = line:lower()
  local city_rank
  local xp_rank

  local rank = lower:match("ranked%s+(%d+)%s+in%s+the%s+city")
  if rank then
    city_rank = tonumber(rank)
  end

  rank = lower:match("ranked%s+(%d+)%s+in%s+the%s+realm")
  if rank then
    xp_rank = tonumber(rank)
  end

  rank = lower:match("ranked%s+(%d+)%s+overall")
  if rank then
    xp_rank = tonumber(rank)
  end

  rank = lower:match("ranked%s+(%d+)%a*%s+in%s+achaea")
  if rank then
    xp_rank = tonumber(rank)
  end

  return city_rank, xp_rank
end

local function parse_army_rank(line)
  if type(line) ~= "string" then return nil end
  if not line:lower():find("army of") then return nil end
  local rank = line:match("%((%d+)%)%s+in the army of")
  if not rank then return nil end
  return tonumber(rank)
end

local function parse_lines(name, lines)
  if not agnosticdb.db.ensure() then
    echo_line("Database not ready; honors update skipped.")
    return
  end

  local record = { name = name }
  local normalized = normalize_person_name(name)
  if not normalized then return end

  for _, line in ipairs(lines) do
    local text = line:gsub("%s+$", "")
    if text ~= "" then
      record.title = record.title or find_title(normalized, text)
      record.class = record.class or find_class(text)
      record.city = record.city or find_city(text)
      record.house = record.house or find_house(text)
      record.race = record.race or find_race(text)

      local lower = text:lower()
      if lower:find("%f[%a]immortal%f[%A]") then
        record.immortal = 1
      end
      if lower:find("%f[%a]dragon%f[%A]") then
        record.dragon = 1
      end

      local city_rank, xp_rank = parse_ranks(text)
      if city_rank then record.city_rank = city_rank end
      if xp_rank then record.xp_rank = xp_rank end

      local army_rank = parse_army_rank(text)
      if army_rank then record.army_rank = army_rank end
    end
  end

  agnosticdb.db.upsert_person(record)
  echo_line(string.format("Honors updated for %s.", normalized))
end

function agnosticdb.honors.abort_capture()
  local capture = agnosticdb.honors.active
  if not capture then return end
  if capture.line_trigger then killTrigger(capture.line_trigger) end
  if capture.prompt_trigger then killTrigger(capture.prompt_trigger) end
  agnosticdb.honors.active = nil
end

local function finish_queue_item()
  if not agnosticdb.honors.queue_running then return end
  local stats = agnosticdb.honors.queue_stats or {}
  stats.processed = (stats.processed or 0) + 1
  agnosticdb.honors.queue_stats = stats
  if #agnosticdb.honors.queue == 0 then
    agnosticdb.honors.queue_running = false
    stats.finished_at = os.time()
    stats.elapsed_seconds = stats.finished_at - (stats.started_at or stats.finished_at)
    local elapsed = stats.elapsed_seconds or 0
    echo_line(string.format("Honors queue complete: %d processed in %ds.", stats.processed or 0, elapsed))
    return
  end
  tempTimer(honors_delay_seconds(), agnosticdb.honors.run_queue)
end

function agnosticdb.honors.finish_capture()
  local capture = agnosticdb.honors.active
  if not capture then return end
  if capture.line_trigger then killTrigger(capture.line_trigger) end
  if capture.prompt_trigger then killTrigger(capture.prompt_trigger) end
  agnosticdb.honors.active = nil

  if capture.name and capture.lines then
    parse_lines(capture.name, capture.lines)
  end
  if capture.on_finish then
    capture.on_finish()
  end
end

function agnosticdb.honors.capture(name, on_finish)
  local normalized = normalize_person_name(name)
  if not normalized then return end

  agnosticdb.honors.abort_capture()
  local capture = {
    name = normalized,
    lines = {},
    on_finish = on_finish
  }
  agnosticdb.honors.active = capture

  if type(tempRegexTrigger) ~= "function" then
    echo_line("Mudlet temp triggers unavailable; cannot capture honors.")
    agnosticdb.honors.capture = nil
    return
  end

  capture.line_trigger = tempRegexTrigger("^.*$", function()
    local text = line or ""
    if text == "" then return end
    if type(isPrompt) == "function" and isPrompt() then
      agnosticdb.honors.finish_capture()
      return
    end
    capture.lines[#capture.lines + 1] = text
  end)

  if type(tempPromptTrigger) == "function" then
    capture.prompt_trigger = tempPromptTrigger(function()
      agnosticdb.honors.finish_capture()
    end)
  end

  echo_line(string.format("Capturing honors for %s...", normalized))
end

function agnosticdb.honors.cancel_queue()
  agnosticdb.honors.queue = {}
  agnosticdb.honors.queue_running = false
  agnosticdb.honors.queue_stats = nil
end

function agnosticdb.honors.queue_names(names)
  if type(names) ~= "table" then return end
  if agnosticdb.honors.queue_running then
    echo_line("Honors queue already running.")
    return
  end

  local seen = {}
  agnosticdb.honors.queue = {}
  for _, name in ipairs(names) do
    local normalized = normalize_person_name(name)
    if normalized and not seen[normalized] then
      seen[normalized] = true
      table.insert(agnosticdb.honors.queue, normalized)
    end
  end

  if #agnosticdb.honors.queue == 0 then
    echo_line("Honors queue has no names to process.")
    return
  end

  agnosticdb.honors.queue_running = true
  agnosticdb.honors.queue_stats = { total = #agnosticdb.honors.queue, processed = 0, started_at = os.time() }
  echo_line(string.format("Honors queue: %d names.", #agnosticdb.honors.queue))
  agnosticdb.honors.run_queue()
end

function agnosticdb.honors.run_queue()
  if not agnosticdb.honors.queue_running then return end
  if #agnosticdb.honors.queue == 0 then
    finish_queue_item()
    return
  end

  local name = table.remove(agnosticdb.honors.queue, 1)
  agnosticdb.honors.capture(name, finish_queue_item)
  send("HONORS " .. name)
end
