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

local function format_duration(seconds)
  if seconds <= 0 then return "0s" end
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

local function attach_queue_progress()
  agnosticdb.api.on_queue_progress = function(percent, stats)
    local total = stats.total or 0
    local processed = stats.processed or 0
    if total > 0 then
      echo_line(string.format("Queue progress: %d%% (%d/%d)", percent, processed, total))
    else
      echo_line(string.format("Queue progress: %d%%", percent))
    end
  end
end

local function ensure_conf_defaults()
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.api = agnosticdb.conf.api or { enabled = true, min_refresh_hours = 24 }
  if agnosticdb.conf.api.enabled == nil then agnosticdb.conf.api.enabled = true end
  agnosticdb.conf.api.min_refresh_hours = agnosticdb.conf.api.min_refresh_hours or 24
  agnosticdb.conf.api.backoff_seconds = agnosticdb.conf.api.backoff_seconds or 30
  agnosticdb.conf.api.min_interval_seconds = agnosticdb.conf.api.min_interval_seconds or 0
  agnosticdb.conf.api.timeout_seconds = agnosticdb.conf.api.timeout_seconds or 15

  agnosticdb.conf.honors = agnosticdb.conf.honors or { delay_seconds = 2 }
  agnosticdb.conf.honors.delay_seconds = agnosticdb.conf.honors.delay_seconds or 2

  if agnosticdb.conf.highlights_enabled == nil then
    agnosticdb.conf.highlights_enabled = true
  end
  agnosticdb.conf.prune_dormant = agnosticdb.conf.prune_dormant or false
  agnosticdb.conf.highlight_ignore = agnosticdb.conf.highlight_ignore or {}

  agnosticdb.conf.highlight = agnosticdb.conf.highlight or { enemies = {}, cities = {} }
  agnosticdb.conf.highlight.enemies = agnosticdb.conf.highlight.enemies or {
    color = "",
    bold = false,
    underline = true,
    italicize = true
  }
  agnosticdb.conf.highlight.cities = agnosticdb.conf.highlight.cities or {}
  local defaults = {
    ashtan = { color = "purple", bold = false, underline = false, italicize = false },
    cyrene = { color = "cornflower_blue", bold = false, underline = false, italicize = false },
    eleusis = { color = "forest_green", bold = false, underline = false, italicize = false },
    hashan = { color = "yellow", bold = false, underline = false, italicize = false },
    mhaldor = { color = "red", bold = false, underline = false, italicize = false },
    targossas = { color = "white", bold = false, underline = false, italicize = false },
    rogue = { color = "orange", bold = false, underline = false, italicize = false },
    divine = { color = "pink", bold = true, underline = false, italicize = true },
    hidden = { color = "green", bold = true, underline = false, italicize = true }
  }
  for key, style in pairs(defaults) do
    agnosticdb.conf.highlight.cities[key] = agnosticdb.conf.highlight.cities[key] or style
    local current = agnosticdb.conf.highlight.cities[key]
    for field, value in pairs(style) do
      if current[field] == nil then
        current[field] = value
      end
    end
  end
end

local function config_theme()
  return {
    accent = "<cyan>",
    border = "<grey>",
    text = "<white>",
    muted = "<silver>",
    reset = "<reset>"
  }
end

local function config_color_palette()
  if agnosticdb.colors and type(agnosticdb.colors.list) == "function" then
    return agnosticdb.colors.list()
  end
  return { "white", "silver", "grey", "cyan", "light_blue", "cornflower_blue", "forest_green", "yellow", "orange", "red", "pink", "purple", "green" }
end

local function config_display_color(value)
  if not value or value == "" then return "none" end
  return value
end

local function config_save()
  if agnosticdb.config and agnosticdb.config.save then
    agnosticdb.config.save()
  end
end

local function config_refresh()
  if agnosticdb.ui and agnosticdb.ui.show_config then
    agnosticdb.ui.show_config()
  end
end

local function config_style_flags(style)
  local flags = {}
  flags[#flags + 1] = style.bold and "B" or "-"
  flags[#flags + 1] = style.underline and "U" or "-"
  flags[#flags + 1] = style.italicize and "I" or "-"
  return table.concat(flags, "")
end

local function config_line_link(text, cmd, hint, theme)
  theme = theme or config_theme()
  cecho(theme.accent)
  setUnderline(true)
  echoLink(text, cmd, "", true)
  setUnderline(false)
  cecho(theme.reset)
end

function agnosticdb.ui.config_noop()
end

local function config_echo_style(label, style, theme)
  theme = theme or config_theme()
  if not style then
    cecho(theme.text .. label)
    return
  end
  if style.color and style.color ~= "" then fg(style.color) end
  if style.bold then setBold(true) end
  if style.underline then setUnderline(true) end
  if style.italicize then setItalics(true) end
  echo(label)
  resetFormat()
  cecho(theme.text)
end

local function config_color_popup(path, theme)
  local commands = {
    string.format("agnosticdb.ui.config_set(%q, %q)", path, "")
  }
  local hints = { "none" }
  local groups = nil
  if agnosticdb.colors and type(agnosticdb.colors.grouped) == "function" then
    groups = agnosticdb.colors.grouped()
  end
  if groups then
    for _, group in ipairs(groups) do
      commands[#commands + 1] = "agnosticdb.ui.config_noop()"
      hints[#hints + 1] = string.format("-- %s --", group.label)
      for _, color in ipairs(group.colors or {}) do
        commands[#commands + 1] = string.format("agnosticdb.ui.config_set(%q, %q)", path, color)
        hints[#hints + 1] = "  " .. color
      end
    end
  else
    for _, color in ipairs(config_color_palette()) do
      commands[#commands + 1] = string.format("agnosticdb.ui.config_set(%q, %q)", path, color)
      hints[#hints + 1] = color
    end
  end

  if type(cechoPopup) == "function" then
    cechoPopup(string.format("%s[color]%s", theme.accent, theme.reset), commands, hints)
    return
  end
  if type(echoPopup) == "function" then
    echoPopup("[color]", commands, hints)
    return
  end
  config_line_link("[color]", string.format("agnosticdb.ui.config_cycle_color(%q)", path), "Cycle color", theme)
end

local function config_city_style(city_key)
  ensure_conf_defaults()
  local cities = agnosticdb.conf.highlight.cities or {}
  local key = tostring(city_key or ""):lower()
  local style = cities[key]
  if not style then
    style = { color = "", bold = false, underline = false, italicize = false }
    cities[key] = style
  end
  if style.color == nil then style.color = "" end
  if style.bold == nil then style.bold = false end
  if style.underline == nil then style.underline = false end
  if style.italicize == nil then style.italicize = false end
  return style
end

local function config_set_boolean(path, value)
  ensure_conf_defaults()
  if path == "api.enabled" then
    agnosticdb.conf.api.enabled = value
    config_save()
  elseif path == "highlights_enabled" then
    if agnosticdb.highlights and agnosticdb.highlights.toggle then
      agnosticdb.highlights.toggle(value)
      config_refresh()
      return
    end
    agnosticdb.conf.highlights_enabled = value
    config_save()
  elseif path == "prune_dormant" then
    agnosticdb.conf.prune_dormant = value
    config_save()
  elseif path == "highlight.enemies.bold" then
    agnosticdb.conf.highlight.enemies.bold = value
    config_save()
  elseif path == "highlight.enemies.underline" then
    agnosticdb.conf.highlight.enemies.underline = value
    config_save()
  elseif path == "highlight.enemies.italicize" then
    agnosticdb.conf.highlight.enemies.italicize = value
    config_save()
  else
    local city, field = path:match("^highlight%.cities%.([%w_]+)%.(bold|underline|italicize)$")
    if city and field then
      local style = config_city_style(city)
      style[field] = value
      config_save()
    else
      echo_line("Config set: unknown key.")
      return
    end
  end

  if agnosticdb.highlights and agnosticdb.highlights.reload then
    agnosticdb.highlights.reload()
  end
  config_refresh()
end

local function config_toggle_boolean(path)
  ensure_conf_defaults()
  local current = false
  if path == "api.enabled" then
    current = agnosticdb.conf.api.enabled
  elseif path == "highlights_enabled" then
    current = agnosticdb.conf.highlights_enabled
  elseif path == "prune_dormant" then
    current = agnosticdb.conf.prune_dormant
  elseif path == "highlight.enemies.bold" then
    current = agnosticdb.conf.highlight.enemies.bold
  elseif path == "highlight.enemies.underline" then
    current = agnosticdb.conf.highlight.enemies.underline
  elseif path == "highlight.enemies.italicize" then
    current = agnosticdb.conf.highlight.enemies.italicize
  else
    local city, field = path:match("^highlight%.cities%.([%w_]+)%.(bold|underline|italicize)$")
    if city and field then
      current = config_city_style(city)[field]
    else
      echo_line("Config toggle: unknown key.")
      return
    end
  end

  config_set_boolean(path, not current)
end

local function config_set_number(path, value)
  ensure_conf_defaults()
  local num = tonumber(value)
  if not num then
    echo_line("Config set: number required.")
    return
  end
  if num < 0 then num = 0 end

  if path == "api.min_refresh_hours" then
    agnosticdb.conf.api.min_refresh_hours = num
  elseif path == "api.min_interval_seconds" then
    agnosticdb.conf.api.min_interval_seconds = num
  elseif path == "api.backoff_seconds" then
    agnosticdb.conf.api.backoff_seconds = num
  elseif path == "api.timeout_seconds" then
    agnosticdb.conf.api.timeout_seconds = num
  elseif path == "honors.delay_seconds" then
    agnosticdb.conf.honors.delay_seconds = num
  else
    echo_line("Config set: unknown key.")
    return
  end

  config_save()
  config_refresh()
end

local function config_cycle_color(path)
  ensure_conf_defaults()
  local palette = config_color_palette()
  local current = ""
  if path == "highlight.enemies.color" then
    current = agnosticdb.conf.highlight.enemies.color or ""
  else
    local city = path:match("^highlight%.cities%.([%w_]+)%.color$")
    if city then
      current = config_city_style(city).color or ""
    else
      echo_line("Config color: unknown key.")
      return
    end
  end

  local next_value = palette[1] or ""
  for i, value in ipairs(palette) do
    if value == current then
      next_value = palette[(i % #palette) + 1]
      break
    end
  end

  if path == "highlight.enemies.color" then
    agnosticdb.conf.highlight.enemies.color = next_value
  else
    local city = path:match("^highlight%.cities%.([%w_]+)%.color$")
    if city then
      config_city_style(city).color = next_value
    end
  end

  config_save()
  if agnosticdb.highlights and agnosticdb.highlights.reload then
    agnosticdb.highlights.reload()
  end
  config_refresh()
end

function agnosticdb.ui.config_toggle(path)
  if not path or path == "" then
    echo_line("Usage: adb config toggle <key>")
    return
  end
  config_toggle_boolean(path)
end

function agnosticdb.ui.config_set(path, value)
  if not path or path == "" or value == nil then
    echo_line("Usage: adb config set <key> <value>")
    return
  end

  ensure_conf_defaults()
  local lower = tostring(path):lower()
  if lower == "api.enabled" or lower == "highlights_enabled" or lower == "prune_dormant"
    or lower == "highlight.enemies.bold" or lower == "highlight.enemies.underline" or lower == "highlight.enemies.italicize" then
    local val = tostring(value):lower()
    local bool = (val == "true" or val == "on" or val == "1" or val == "yes")
    if val == "false" or val == "off" or val == "0" or val == "no" then
      bool = false
    end
    config_set_boolean(lower, bool)
    return
  end

  if lower == "highlight.enemies.color" then
    agnosticdb.conf.highlight.enemies.color = tostring(value)
    config_save()
    if agnosticdb.highlights and agnosticdb.highlights.reload then
      agnosticdb.highlights.reload()
    end
    config_refresh()
    return
  end

  local city, field = lower:match("^highlight%.cities%.([%w_]+)%.(color|bold|underline|italicize)$")
  if city and field then
    local style = config_city_style(city)
    if field == "color" then
      style.color = tostring(value)
    else
      local val = tostring(value):lower()
      style[field] = (val == "true" or val == "on" or val == "1" or val == "yes")
    end
    config_save()
    if agnosticdb.highlights and agnosticdb.highlights.reload then
      agnosticdb.highlights.reload()
    end
    config_refresh()
    return
  end

  config_set_number(lower, value)
end

function agnosticdb.ui.config_step(path, delta)
  if not path or path == "" then return end
  ensure_conf_defaults()
  local current = 0
  if path == "api.min_refresh_hours" then
    current = agnosticdb.conf.api.min_refresh_hours or 0
  elseif path == "api.min_interval_seconds" then
    current = agnosticdb.conf.api.min_interval_seconds or 0
  elseif path == "api.backoff_seconds" then
    current = agnosticdb.conf.api.backoff_seconds or 0
  elseif path == "api.timeout_seconds" then
    current = agnosticdb.conf.api.timeout_seconds or 0
  elseif path == "honors.delay_seconds" then
    current = agnosticdb.conf.honors.delay_seconds or 0
  else
    echo_line("Config step: unknown key.")
    return
  end
  local next_value = current + (tonumber(delta) or 0)
  if next_value < 0 then next_value = 0 end
  config_set_number(path, next_value)
end

function agnosticdb.ui.config_cycle_color(path)
  if not path or path == "" then return end
  config_cycle_color(path)
end

function agnosticdb.ui.show_ignore_list()
  ensure_conf_defaults()
  local ignored = agnosticdb.conf.highlight_ignore or {}
  local names = {}
  for name in pairs(ignored) do
    names[#names + 1] = name
  end
  table.sort(names, function(a, b) return a:lower() < b:lower() end)
  echo_line(string.format("Highlight ignore list: %d name(s).", #names))
  for _, name in ipairs(names) do
    echo_line("  " .. name)
  end
end

function agnosticdb.ui.show_config()
  ensure_conf_defaults()
  local conf = agnosticdb.conf
  local theme = config_theme()
  local width = 88
  local header_label = "agnosticDB Config"
  local footer_label = "agnosticDB"

  local function header_line()
    return string.format("%s┌─%s%s%s─┐%s", theme.border, theme.accent, header_label, theme.border, theme.reset)
  end

  local function separator()
    return string.format("%s%s%s", theme.border, string.rep("─", width), theme.reset)
  end

  local function section(title, padding)
    padding = padding or ""
    return string.format("%s%s└─%s%s%s─┘%s", padding, theme.border, theme.accent, title, theme.border, theme.reset)
  end

  local function footer_line()
    local tab = string.format("└─%s%s%s─┘", theme.accent, footer_label, theme.border)
    local padding = math.max(0, width - (#footer_label + 4))
    return string.format("%s%s%s%s", string.rep(" ", padding), theme.border, tab, theme.reset)
  end

  local function line(text)
    cecho(text .. "\n")
  end

  local function bool_label(value)
    return value and "on" or "off"
  end

  local function number_line(label, key, value, step)
    cecho(string.format("%s  %s: %s%d", theme.text, label, theme.text, value))
    cecho(" ")
    config_line_link("[-]", string.format("agnosticdb.ui.config_step(%q, -%d)", key, step), "Decrease", theme)
    cecho(" ")
    config_line_link("[+]", string.format("agnosticdb.ui.config_step(%q, %d)", key, step), "Increase", theme)
    cecho("\n")
  end

  local function toggle_line(label, key, value)
    cecho(string.format("%s  %s: %s%s", theme.text, label, theme.text, bool_label(value)))
    cecho(" ")
    config_line_link("[toggle]", string.format("agnosticdb.ui.config_toggle(%q)", key), "Toggle", theme)
    cecho("\n")
  end

  line(header_line())
  line(separator())
  line(section("Quick Toggles"))
  toggle_line("API enabled", "api.enabled", conf.api.enabled)
  toggle_line("Highlights enabled", "highlights_enabled", conf.highlights_enabled)
  line(separator())
  line(section("API Timing"))
  number_line("Min refresh hours", "api.min_refresh_hours", conf.api.min_refresh_hours or 0, 1)
  number_line("Min interval seconds", "api.min_interval_seconds", conf.api.min_interval_seconds or 0, 1)
  number_line("Backoff seconds", "api.backoff_seconds", conf.api.backoff_seconds or 0, 5)
  number_line("Timeout seconds", "api.timeout_seconds", conf.api.timeout_seconds or 0, 5)
  line(separator())
  line(section("Honors"))
  number_line("Delay seconds", "honors.delay_seconds", conf.honors.delay_seconds or 0, 1)
  line(separator())
  line(section("Highlights"))
  local enemy_style = conf.highlight.enemies
  cecho(theme.text .. "  ")
  config_echo_style("Enemy", enemy_style, theme)
  cecho(string.format("%s style: %s%s %s", theme.text, theme.text, config_display_color(enemy_style.color), config_style_flags(enemy_style)))
  cecho(" ")
  config_color_popup("highlight.enemies.color", theme)
  cecho(" ")
  config_line_link("[B]", "agnosticdb.ui.config_toggle('highlight.enemies.bold')", "Toggle bold", theme)
  cecho(" ")
  config_line_link("[U]", "agnosticdb.ui.config_toggle('highlight.enemies.underline')", "Toggle underline", theme)
  cecho(" ")
  config_line_link("[I]", "agnosticdb.ui.config_toggle('highlight.enemies.italicize')", "Toggle italic", theme)
  cecho("\n")

  local city_order = {
    "ashtan",
    "cyrene",
    "eleusis",
    "hashan",
    "mhaldor",
    "targossas",
    "rogue",
    "divine",
    "hidden"
  }
  for _, city in ipairs(city_order) do
    local style = config_city_style(city)
    local label = city:sub(1, 1):upper() .. city:sub(2)
    cecho(theme.text .. "  ")
    config_echo_style(label, style, theme)
    cecho(string.format("%s: %s%s %s", theme.text, theme.text, config_display_color(style.color), config_style_flags(style)))
    cecho(" ")
    config_color_popup(string.format("highlight.cities.%s.color", city), theme)
    cecho(" ")
    config_line_link("[B]", string.format("agnosticdb.ui.config_toggle('highlight.cities.%s.bold')", city), "Toggle bold", theme)
    cecho(" ")
    config_line_link("[U]", string.format("agnosticdb.ui.config_toggle('highlight.cities.%s.underline')", city), "Toggle underline", theme)
    cecho(" ")
    config_line_link("[I]", string.format("agnosticdb.ui.config_toggle('highlight.cities.%s.italicize')", city), "Toggle italic", theme)
    cecho("\n")
  end

  local ignored_count = 0
  for _ in pairs(conf.highlight_ignore or {}) do ignored_count = ignored_count + 1 end
  cecho(string.format("%s  Ignore list: %s%d name(s)", theme.text, theme.text, ignored_count))
  cecho(" ")
  config_line_link("[show]", "agnosticdb.ui.show_ignore_list()", "Show ignore list", theme)
  cecho(" ")
  config_line_link("[manage]", "agnosticdb.ui.show_help()", "Use adb ignore <name>", theme)
  cecho("\n")
  cecho(theme.muted .. "  Tip: right-click [color] to pick from the full palette." .. theme.reset .. "\n")

  line(separator())
  line(section("Politics"))
  cecho(theme.text .. "  Open politics menu ")
  config_line_link("[open]", "agnosticdb.ui.show_politics()", "Open politics menu", theme)
  cecho("\n")
  line(separator())
  line(section("Advanced"))
  toggle_line("Prune dormant", "prune_dormant", conf.prune_dormant)
  cecho(theme.muted .. "  Tip: adb config set <key> <value> for exact values." .. theme.reset .. "\n")
  line(separator())
  line(footer_line())
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
  entry("adb refresh", "force refresh all online names")
  entry("adb quick", "fetch online list (new names only)")
  entry("adb update", "refresh all known names")
  entry("adb stats", "counts by class/city")
  entry("adb ignore <name>", "toggle highlight ignore")
  entry("adb config", "open configuration UI")
  entry("adb config set <key> <value>", "set config values")
  entry("adb config toggle <key>", "toggle config values")
  entry("adb honors <name>", "request honors + ingest")
  entry("adb honors online", "request honors for all online names")
  entry("adb list class|city|race <value>", "list people by class/city/race")
  entry("adb list enemy", "list people marked as enemies")
  entry("adb dbcheck", "check database health")
  entry("adb dbreset", "reset database (drops people table)")
  entry("adb forget <name>", "remove a person from the database")
  entry("adbtest", "run self-test")
  entry("qwp", "online list grouped by city")
  entry("qwpr", "online list grouped by city + race")
  entry("qwpa", "online list grouped by city + army rank")
  entry("qwpc", "online list grouped by city + class")
  entry("qwprc", "online list grouped by city + race/class")
  entry("qwpcr", "online list grouped by city + class/race")
  entry("qwp rank <n>", "online list grouped by city, filtered by army rank")
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
  if person.race and person.race ~= "" then
    echo_line(string.format("Race: %s", person.race))
  end
  echo_line(string.format("City: %s", person.city ~= "" and person.city or "(unknown)"))
  echo_line(string.format("House: %s", person.house ~= "" and person.house or "(unknown)"))
  if person.army_rank and person.army_rank >= 0 then
    echo_line(string.format("Army Rank: %d", person.army_rank))
  end
  if person.enemy_city and person.enemy_city ~= "" then
    echo_line(string.format("Enemied to City: %s", person.enemy_city))
  end
  if person.enemy_house and person.enemy_house ~= "" then
    echo_line(string.format("Enemied to House: %s", person.enemy_house))
  end
  echo_line(string.format("IFF: %s", person.iff or "auto"))
  if person.notes and person.notes ~= "" then
    echo_line("Notes:")
    echo_line(person.notes)
  end
  if person.xp_rank and person.xp_rank >= 0 then
    echo_line(string.format("XP Rank: %d", person.xp_rank))
  end
  if person.level and person.level >= 0 then
    echo_line(string.format("Level: %d", person.level))
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
  attach_queue_progress()
  agnosticdb.api.on_queue_done = function(stats)
    echo_line(string.format("Queue complete: ok=%d cached=%d pruned=%d api_error=%d decode_failed=%d download_error=%d other=%d",
      stats.ok, stats.cached, stats.pruned, stats.api_error, stats.decode_failed, stats.download_error, stats.other))
    if stats.elapsed_seconds then
      echo_line(string.format("Queue time: %s", format_duration(stats.elapsed_seconds)))
    end
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

function agnosticdb.ui.refresh_online()
  echo_line("Refreshing online list (force)...")
  attach_queue_progress()
  agnosticdb.api.on_queue_done = function(stats)
    echo_line(string.format("Queue complete: ok=%d cached=%d pruned=%d api_error=%d decode_failed=%d download_error=%d other=%d",
      stats.ok, stats.cached, stats.pruned, stats.api_error, stats.decode_failed, stats.download_error, stats.other))
    if stats.elapsed_seconds then
      echo_line(string.format("Queue time: %s", format_duration(stats.elapsed_seconds)))
    end
  end
  agnosticdb.api.fetch_online(function(result, status)
    if status ~= "ok" then
      echo_line(string.format("Refresh online failed (%s).", status or "unknown"))
      return
    end

    echo_line(string.format("Online list: %d names, %d added, %d queued.", #result.names, result.added, result.queued))
    local eta = agnosticdb.api.estimate_queue_seconds(0)
    echo_line(string.format("Estimated completion: ~%s", format_eta(eta)))
  end, { force = true })
end

function agnosticdb.ui.db_check()
  local ok, info = agnosticdb.db.check()
  if ok then
    echo_line("Database check: OK.")
  else
    echo_line("Database check: issues found.")
  end
  if type(info) == "table" then
    for _, line in ipairs(info) do
      echo_line("  " .. line)
    end
  elseif type(info) == "string" then
    echo_line("  " .. info)
  end
end

function agnosticdb.ui.db_reset()
  echo_line("Resetting database...")
  local ok, err = agnosticdb.db.reset()
  if not ok then
    echo_line(string.format("Database reset failed: %s", err or "unknown"))
    echo_line("Delete the agnosticdb database file and reload.")
    return
  end

  if agnosticdb.highlights and agnosticdb.highlights.clear then
    agnosticdb.highlights.clear()
  end
  if agnosticdb.highlights and agnosticdb.highlights.reload then
    agnosticdb.highlights.reload()
  end

  echo_line("Database reset complete.")
end

function agnosticdb.ui.forget(name)
  if not name or name == "" then
    echo_line("Provide a name to remove.")
    return
  end
  agnosticdb.db.delete_person(name)
  echo_line(string.format("Removed %s from the database.", display_name(name)))
end

function agnosticdb.ui.honors(name)
  if not name or name == "" then
    echo_line("Provide a name to honor-check.")
    return
  end
  if agnosticdb.honors and agnosticdb.honors.queue_running then
    agnosticdb.honors.cancel_queue()
  end
  if agnosticdb.honors and agnosticdb.honors.capture then
    agnosticdb.honors.capture(name)
  end
  send("HONORS " .. name)
end

function agnosticdb.ui.honors_online()
  echo_line("Queueing honors for online names...")
  agnosticdb.api.fetch_list(function(names, status)
    if status ~= "ok" or type(names) ~= "table" then
      echo_line(string.format("Honors online failed (%s).", status or "unknown"))
      return
    end
    if agnosticdb.honors and agnosticdb.honors.queue_names then
      agnosticdb.honors.queue_names(names)
    end
  end)
end

local function list_help()
  echo_line("Usage: adb list class|city|race <value> | adb list enemy")
end

local function list_matches(value, candidate)
  if type(value) ~= "string" or type(candidate) ~= "string" then return false end
  if value == "" or candidate == "" then return false end
  return value:lower() == candidate:lower()
end

function agnosticdb.ui.list(filter, value)
  if not filter or filter == "" then
    list_help()
    return
  end

  if not agnosticdb.db.ensure() then
    echo_line("List unavailable (DB not initialized).")
    return
  end

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  if not rows or #rows == 0 then
    echo_line("List: no people in DB.")
    return
  end

  local results = {}
  if filter == "enemy" then
    for _, row in ipairs(rows) do
      if row.name and agnosticdb.iff.is_enemy(row.name) then
        results[#results + 1] = row
      end
    end
  elseif filter == "class" or filter == "city" or filter == "race" then
    if not value or value == "" then
      list_help()
      return
    end
    for _, row in ipairs(rows) do
      local field = row[filter] or ""
      if list_matches(value, field) then
        results[#results + 1] = row
      end
    end
  else
    list_help()
    return
  end

  table.sort(results, function(a, b)
    return (a.name or ""):lower() < (b.name or ""):lower()
  end)

  local label = filter
  if value and value ~= "" then
    label = string.format("%s %s", filter, value)
  end
  echo_line(string.format("List (%s): %d", label, #results))
  for _, row in ipairs(results) do
    local parts = {}
    if row.city and row.city ~= "" then parts[#parts + 1] = row.city end
    if row.class and row.class ~= "" then parts[#parts + 1] = row.class end
    if row.race and row.race ~= "" then parts[#parts + 1] = row.race end
    local suffix = ""
    if #parts > 0 then
      suffix = " (" .. table.concat(parts, ", ") .. ")"
    end
    echo_line(string.format("%s%s", display_name(row.name), suffix))
  end
end

function agnosticdb.ui.quick_update()
  echo_line("Fetching online list (new names only)...")
  attach_queue_progress()
  agnosticdb.api.on_queue_done = function(stats)
    echo_line(string.format("Queue complete: ok=%d cached=%d pruned=%d api_error=%d decode_failed=%d download_error=%d other=%d",
      stats.ok, stats.cached, stats.pruned, stats.api_error, stats.decode_failed, stats.download_error, stats.other))
    if stats.elapsed_seconds then
      echo_line(string.format("Queue time: %s", format_duration(stats.elapsed_seconds)))
    end
  end
  agnosticdb.api.fetch_online_new(function(result, status)
    if status ~= "ok" then
      echo_line(string.format("Quick update failed (%s).", status or "unknown"))
      return
    end

    echo_line(string.format("Online list: %d names, %d new, %d queued.", #result.names, result.added, result.queued))
    local eta = agnosticdb.api.estimate_queue_seconds(0)
    echo_line(string.format("Estimated completion: ~%s", format_eta(eta)))
  end)
end

function agnosticdb.ui.update_all()
  echo_line("Queueing updates for all known names...")
  attach_queue_progress()
  agnosticdb.api.on_queue_done = function(stats)
    echo_line(string.format("Queue complete: ok=%d cached=%d pruned=%d api_error=%d decode_failed=%d download_error=%d other=%d",
      stats.ok, stats.cached, stats.pruned, stats.api_error, stats.decode_failed, stats.download_error, stats.other))
    if stats.elapsed_seconds then
      echo_line(string.format("Queue time: %s", format_duration(stats.elapsed_seconds)))
    end
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

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
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

local function race_label(race_name)
  if not race_name or race_name == "" then return "UNK" end
  return race_name
end

local function army_rank_label(rank)
  if rank == nil or rank < 0 then return "AR?" end
  return string.format("AR%d", rank)
end

local function qwp_suffix(person, mode)
  if mode == "none" then return nil end
  local race = person.race or ""
  local race_text = race_label(race)
  local class_text = class_abbrev(person.class)
  local elemental_or_dragon = race == "Elemental" or race == "Dragon"

  if mode == "army" then
    return army_rank_label(person.army_rank)
  end
  if mode == "class" then
    if elemental_or_dragon then
      return race_text
    end
    return class_text
  end
  if mode == "race" then
    return race_text
  end
  if mode == "race_class" then
    return string.format("%s/%s", race_text, class_text)
  end
  if mode == "class_race" then
    return string.format("%s/%s", class_text, race_text)
  end
  return nil
end

local function qwp_match_filter(person, filter)
  if not filter then return true end
  if filter.field == "army_rank" then
    local value = tonumber(filter.value or -1)
    return tonumber(person.army_rank or -1) >= value
  end
  return true
end

local function has_army_rank(person)
  return tonumber(person.army_rank or -1) >= 0
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

function agnosticdb.ui.qwp(mode, filter)
  local view_mode = mode
  if view_mode == true then
    view_mode = "class"
  elseif view_mode == false or view_mode == nil then
    view_mode = "none"
  end
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
      local entry = {
        name = display_name(name),
        class = person.class or "",
        race = person.race or "",
        army_rank = person.army_rank
      }
      local include = true
      if view_mode == "army" and not has_army_rank(entry) then
        include = false
      end
      if include and qwp_match_filter(entry, filter) then
        city_online[city] = city_online[city] or {}
        city_online[city][#city_online[city] + 1] = entry
      end
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
        local suffix = qwp_suffix(player, view_mode)
        if suffix and suffix ~= "" then
          label = string.format("%s (%s)", player.name, suffix)
        end
        cecho(string.format("<%s>%s<reset> ", color, label))
      end
    end
    cecho("\n")
  end)
end
