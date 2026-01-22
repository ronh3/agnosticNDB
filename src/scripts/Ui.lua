agnosticdb = agnosticdb or {}

agnosticdb.ui = agnosticdb.ui or {}

local function prefix()
  return "<0,200,200>[agnosticdb]<r> "
end

local function echo_line(text)
  decho(prefix() .. text .. "\n")
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
  echo_line("Commands:")
  echo_line("  adb politics")
  echo_line("  adb highlights on|off")
  echo_line("  adb highlights reload|clear")
  echo_line("  adb note <name> <notes>")
  echo_line("  adb note <name>")
  echo_line("  adb iff <name> enemy|ally|auto")
  echo_line("  adb whois <name>")
  echo_line("  adb fetch [name]")
  echo_line("  adb update")
  echo_line("  adb stats")
  echo_line("  adb ignore <name>")
  echo_line("  adbtest")
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
  local person = agnosticdb.db.get_person(name)
  if not person then
    agnosticdb.api.fetch(name, function(fetched, status)
      if not fetched then
        echo_line(string.format("No data for %s (%s).", name, status or "unknown"))
        return
      end
      echo_line(string.format("Fetch status: %s", status or "ok"))
      agnosticdb.ui.show_person(fetched.name)
    end)
    return
  end

  echo_line(string.format("Name: %s", person.name))
  echo_line(string.format("Class: %s", person.class or ""))
  echo_line(string.format("City: %s", person.city or ""))
  echo_line(string.format("House: %s", person.house or ""))
  echo_line(string.format("Order: %s", person.order or ""))
  echo_line(string.format("IFF: %s", person.iff or "auto"))
  if person.notes and person.notes ~= "" then
    echo_line("Notes:")
    echo_line(person.notes)
  end
end

function agnosticdb.ui.set_note(name, notes)
  agnosticdb.notes.set(name, notes)
  echo_line(string.format("Notes saved for %s.", name))
end

function agnosticdb.ui.show_note(name)
  local note = agnosticdb.notes.get(name)
  if not note or note == "" then
    echo_line(string.format("No notes for %s.", name))
    return
  end
  echo_line(string.format("Notes for %s:", name))
  echo_line(note)
end

function agnosticdb.ui.set_iff(name, status)
  agnosticdb.iff.set(name, status)
  echo_line(string.format("IFF for %s set to %s.", name, status))
end

function agnosticdb.ui.toggle_ignore(name)
  if agnosticdb.highlights.is_ignored(name) then
    agnosticdb.highlights.unignore(name)
    echo_line(string.format("%s removed from highlight ignore list.", name))
  else
    agnosticdb.highlights.ignore(name)
    echo_line(string.format("%s added to highlight ignore list.", name))
  end
  agnosticdb.highlights.reload()
end

function agnosticdb.ui.fetch_and_show(name)
  agnosticdb.api.fetch(name, function(person, status)
    if not person then
      echo_line(string.format("Fetch failed for %s (%s).", name, status or "unknown"))
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
