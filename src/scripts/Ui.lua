agnosticdb = agnosticdb or {}

agnosticdb.ui = agnosticdb.ui or {}

local function prefix()
  return "<cyan>[agnosticdb]<reset> "
end

local function echo_line(text)
  cecho(prefix() .. text .. "\n")
end

local function display_name(name)
  if agnosticdb and agnosticdb.db and agnosticdb.db.normalize_name then
    return agnosticdb.db.normalize_name(name) or name
  end
  return name
end

local function format_eta(seconds)
  if seconds <= 0 then return "now" end
  local secs = math.floor(seconds)
  local mins = math.floor(secs / 60)
  secs = secs % 60
  local hours = math.floor(mins / 60)
  mins = mins % 60

  if hours > 0 then
    return string.format("%dh %dm %ds", hours, mins, secs)
  end
  if mins > 0 then
    return string.format("%dm %ds", mins, secs)
  end
  return string.format("%ds", secs)
end

function agnosticdb.ui.show_help()
  local accent = "<cyan>"
  local text = "<white>"
  local border = "<grey>"
  local reset = "<reset>"
  local cmd_pad = 24
  local header = "agnosticDB Help"

  local function emit(raw)
    cecho(raw .. "\n")
  end

  local function line()
    emit(border .. string.rep("-", 70) .. reset)
  end

  local function header_line()
    emit(border .. "+ " .. accent .. header .. border .. " +" .. reset)
  end

  local function entry(cmd, desc)
    emit(string.format("%s%-24s%s | %s%s%s", accent, cmd, reset, text, desc, reset))
  end

  line()
  header_line()
  line()
  entry("adb politics", "show politics menu")
  entry("adb highlights on|off", "toggle highlights")
  entry("adb highlights reload", "rebuild highlight triggers")
  entry("adb highlights clear", "remove all highlight triggers")
  entry("adb note <name> <notes>", "set notes")
  entry("adb note <name>", "show notes")
  entry("adb note clear <name>", "clear notes for a person")
  entry("adb note clear all", "clear notes for everyone")
  entry("adb iff <name> enemy|ally|auto", "set friend/foe status")
  entry("adb whois <name>", "show stored data (fetch if needed)")
  entry("adb fetch [name]", "fetch online list or single person")
  entry("adb update", "refresh all known names")
  entry("adb stats", "counts by class/city")
  entry("adb ignore <name>", "toggle highlight ignore")
  entry("adbtest", "run self-test")
  entry("qwp", "online list grouped by city")
  entry("qwpc", "online list grouped by city + class")
  line()
end

function agnosticdb.ui.show_politics()
  echo_line("City relations (click to toggle):")
  for _, city in ipairs(agnosticdb.politics.cities) do
    local relation = agnosticdb.politics.get_city_relation(city)
    local cmd = string.format("agnosticdb.politics.toggle_city_relation(%q); agnosticdb.ui.show_politics()", city)
    setUnderline(true)
    echoLink(string.format("  %s: %s", city, relation), cmd, "Click to cycle relation", true)
    setUnderline(false)
    echo("\n")
  end

  local enabled = agnosticdb.conf and agnosticdb.conf.highlights_enabled
  local cmd = string.format("agnosticdb.highlights.toggle(%s); agnosticdb.ui.show_politics()", enabled and "false" or "true")
  setUnderline(true)
  echoLink(string.format("Highlights: %s", enabled and "on" or "off"), cmd, "Toggle highlights", true)
  setUnderline(false)
  echo("\n")
end

function agnosticdb.ui.show_person(name)
  local shown_name = display_name(name)
  local person = agnosticdb.db.get_person(name)
  if not person then
    agnosticdb.api.fetch(name, function(fetched, status)
      if not fetched then
        echo_line(string.format("No data for %s (%s).", shown_name, status or "unknown"))
        return
      end
      echo_line(string.format("Fetch status: %s", status or "ok"))
      agnosticdb.ui.show_person(fetched.name)
    end)
    return
  end

  echo_line(string.format("Name: %s", person.name))
  echo_line(string.format("Class: %s", person.class ~= "" and person.class or "(unknown)"))
  echo_line(string.format("City: %s", person.city ~= "" and person.city or "(unknown)"))
  echo_line(string.format("House: %s", person.house ~= "" and person.house or "(unknown)"))
  echo_line(string.format("IFF: %s", person.iff or "auto"))
  if person.notes and person.notes ~= "" then
    echo_line("Notes:")
    echo_line(person.notes)
  end
end

function agnosticdb.ui.set_note(name, notes)
  agnosticdb.notes.set(name, notes)
  echo_line(string.format("Notes saved for %s.", display_name(name)))
end

function agnosticdb.ui.show_note(name)
  local note = agnosticdb.notes.get(name)
  if not note or note == "" then
    echo_line(string.format("No notes for %s.", display_name(name)))
    return
  end
  echo_line(string.format("Notes for %s:", display_name(name)))
  echo_line(note)
end

function agnosticdb.ui.clear_note(name)
  agnosticdb.notes.clear(name)
  echo_line(string.format("Notes cleared for %s.", display_name(name)))
end

function agnosticdb.ui.clear_all_notes()
  local count = agnosticdb.notes.clear_all()
  echo_line(string.format("Notes cleared for %d people.", count))
end

function agnosticdb.ui.set_iff(name, status)
  agnosticdb.iff.set(name, status)
  echo_line(string.format("IFF for %s set to %s.", display_name(name), status))
end

function agnosticdb.ui.toggle_ignore(name)
  local shown_name = display_name(name)
  if agnosticdb.highlights.is_ignored(name) then
    agnosticdb.highlights.unignore(name)
    echo_line(string.format("%s removed from highlight ignore list.", shown_name))
  else
    agnosticdb.highlights.ignore(name)
    echo_line(string.format("%s added to highlight ignore list.", shown_name))
  end
  agnosticdb.highlights.reload()
end

function agnosticdb.ui.fetch_and_show(name)
  agnosticdb.api.fetch(name, function(person, status)
    if not person then
      echo_line(string.format("Fetch failed for %s (%s).", display_name(name), status or "unknown"))
      return
    end
    echo_line(string.format("Fetch status: %s", status or "ok"))
    agnosticdb.ui.show_person(person.name)
    agnosticdb.highlights.reload()
  end)
end

function agnosticdb.ui.fetch(name)
  if name and name ~= "" then
    agnosticdb.ui.fetch_and_show(name)
    local eta = agnosticdb.api.estimate_queue_seconds(0)
    echo_line(string.format("Estimated completion: ~%s", format_eta(eta)))
    return
  end

  echo_line("Fetching online list...")
  agnosticdb.api.on_queue_done = function(stats)
    echo_line(string.format("Queue complete: ok=%d cached=%d pruned=%d api_error=%d decode_failed=%d download_error=%d other=%d",
      stats.ok, stats.cached, stats.pruned, stats.api_error, stats.decode_failed, stats.download_error, stats.other))
  end
  agnosticdb.api.fetch_online(function(result, status)
    if status ~= "ok" then
      echo_line(string.format("Fetch online failed (%s).", status or "unknown"))
      return
    end

    echo_line(string.format("Online list: %d names, %d added, %d queued.", #result.names, result.added, result.queued))
    local eta = agnosticdb.api.estimate_queue_seconds(0)
    echo_line(string.format("Estimated completion: ~%s", format_eta(eta)))
  end)
end

function agnosticdb.ui.update_all()
  echo_line("Queueing updates for all known names...")
  agnosticdb.api.on_queue_done = function(stats)
    echo_line(string.format("Queue complete: ok=%d cached=%d pruned=%d api_error=%d decode_failed=%d download_error=%d other=%d",
      stats.ok, stats.cached, stats.pruned, stats.api_error, stats.decode_failed, stats.download_error, stats.other))
  end
  agnosticdb.api.update_all(function(result, status)
    if status ~= "ok" then
      echo_line(string.format("Update failed (%s).", status or "unknown"))
      return
    end

    echo_line(string.format("Queued %d updates (from %d names).", result.queued, result.count))
    local eta = agnosticdb.api.estimate_queue_seconds(0)
    echo_line(string.format("Estimated completion: ~%s", format_eta(eta)))
  end, { force = true })
end

function agnosticdb.ui.highlights_toggle(mode)
  local enabled = (mode == "on" or mode == true)
  agnosticdb.highlights.toggle(enabled)
  echo_line(string.format("Highlights: %s", enabled and "on" or "off"))
end

function agnosticdb.ui.highlights_reload()
  agnosticdb.highlights.reload()
  echo_line("Highlights reloaded.")
end

function agnosticdb.ui.highlights_clear()
  agnosticdb.highlights.clear()
  echo_line("Highlights cleared.")
end

local function sorted_keys(map)
  local keys = {}
  for k, _ in pairs(map) do
    keys[#keys + 1] = k
  end
  table.sort(keys)
  return keys
end

function agnosticdb.ui.stats()
  if not agnosticdb.db.people then
    echo_line("Stats unavailable (DB not initialized).")
    return
  end

  local rows = db:fetch(agnosticdb.db.people)
  if not rows or #rows == 0 then
    echo_line("Stats: no people in DB.")
    return
  end

  local by_class = {}
  local by_city = {}

  for _, row in ipairs(rows) do
    local class = row.class or ""
    local city = row.city or ""
    if class == "" then class = "(unknown)" end
    if city == "" or city == "(none)" then city = "Rogue" end
    by_class[class] = (by_class[class] or 0) + 1
    by_city[city] = (by_city[city] or 0) + 1
  end

  echo_line(string.format("Stats: %d people total", #rows))
  echo_line("By class:")
  for _, key in ipairs(sorted_keys(by_class)) do
    echo_line(string.format("  %s: %d", key, by_class[key]))
  end
  echo_line("By city:")
  for _, key in ipairs(sorted_keys(by_city)) do
    echo_line(string.format("  %s: %d", key, by_city[key]))
  end
end

local function class_abbrev_map()
  return {
    Alchemist = "ALC",
    Apostate = "APO",
    Bard = "BARD",
    Blademaster = "BM",
    Depthswalker = "DEP",
    Druid = "DRU",
    Infernal = "INF",
    Jester = "JEST",
    Magi = "MAG",
    Monk = "MNK",
    Occultist = "OCC",
    Paladin = "PAL",
    Pariah = "PAR",
    Priest = "PRST",
    Psion = "PSI",
    Runewarden = "RUNW",
    Sentinel = "SENT",
    Serpent = "SERP",
    Shaman = "SHAM",
    Sylvan = "SYL",
    Unnamable = "UNAM"
  }
end

local function class_abbrev(class_name)
  if not class_name or class_name == "" then return "UNK" end
  local map = class_abbrev_map()
  local match = map[class_name]
  if match then return match end
  local up = class_name:upper()
  if #up <= 4 then return up end
  return up:sub(1, 4)
end

local function city_color(city)
  local cfg = agnosticdb.conf and agnosticdb.conf.highlight and agnosticdb.conf.highlight.cities or {}
  local key = city:lower()
  if cfg[key] and cfg[key].color and cfg[key].color ~= "" then
    return cfg[key].color
  end
  return "white"
end

local function normalize_city_name(city)
  if city == "" or city == "(none)" then return "Rogue" end
  if city == "(hidden)" then return "Hidden" end
  return city
end

function agnosticdb.ui.qwp(with_class)
  echo_line("Building online list...")
  agnosticdb.api.fetch_list(function(names, status)
    if status ~= "ok" or type(names) ~= "table" then
      echo_line(string.format("Online list failed (%s).", status or "unknown"))
      return
    end

    agnosticdb.api.seed_names(names, "api_list")

    local city_online = {}
    for _, name in ipairs(names) do
      local person = agnosticdb.db.get_person(name) or {}
      local city = normalize_city_name(person.city or "")
      city_online[city] = city_online[city] or {}
      city_online[city][#city_online[city] + 1] = {
        name = display_name(name),
        class = person.class or ""
      }
    end

    local city_list = {}
    for city, players in pairs(city_online) do
      city_list[#city_list + 1] = { name = city, size = #players, players = players }
    end

    table.sort(city_list, function(a, b)
      if a.size == b.size then
        return a.name:lower() < b.name:lower()
      end
      return a.size > b.size
    end)

    for _, city in ipairs(city_list) do
      table.sort(city.players, function(a, b)
        return a.name:lower() < b.name:lower()
      end)

      local color = city_color(city.name)
      cecho(string.format("\n<%s>%s: <grey>(<white>%d<grey>)<reset> ", color, city.name, city.size))

      for _, player in ipairs(city.players) do
        local label = player.name
        if with_class then
          label = string.format("%s (%s)", player.name, class_abbrev(player.class))
        end
        cecho(string.format("<%s>%s<reset> ", color, label))
      end
    end
    cecho("\n")
  end)
end
