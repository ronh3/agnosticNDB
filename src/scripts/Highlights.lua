agnosticdb = agnosticdb or {}

agnosticdb.highlights = agnosticdb.highlights or {}

local function is_enabled()
  agnosticdb.conf = agnosticdb.conf or {}
  if agnosticdb.conf.highlights_enabled == nil then
    agnosticdb.conf.highlights_enabled = true
  end
  return agnosticdb.conf.highlights_enabled
end

local function highlight_color()
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.colors = agnosticdb.conf.colors or { enemy = "red", ally = "green" }
  return agnosticdb.conf.colors
end

local function highlight_config()
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.highlight = agnosticdb.conf.highlight or { enemies = {}, cities = {} }
  return agnosticdb.conf.highlight
end

local function highlight_ignore()
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.highlight_ignore = agnosticdb.conf.highlight_ignore or {}
  return agnosticdb.conf.highlight_ignore
end

local function apply_style(name, style)
  if not line or not name then return end
  local pattern = "%f[%a]" .. name .. "%f[%A]"
  local start_pos = 1
  local occurrence = 0

  while true do
    local s, e = line:find(pattern, start_pos)
    if not s then break end
    occurrence = occurrence + 1

    if type(selectSection) == "function" then
      selectSection(s, e)
    else
      selectString(name, occurrence)
    end

    if style.color then fg(style.color) end
    if style.bold then setBold(true) end
    if style.underline then setUnderline(true) end
    if style.italicize then setItalics(true) end
    resetFormat()

    start_pos = e + 1
  end
end

local function style_for(person)
  if not person or not person.name then return nil end
  local config = highlight_config()
  local style = {}

  local city = person.city or ""
  if city == "" or city == "(none)" then city = "Rogue" end
  local key = city:lower()

  local city_cfg = config.cities and config.cities[key]
  if city_cfg then
    style.color = city_cfg.color
    style.bold = city_cfg.bold
    style.underline = city_cfg.underline
    style.italicize = city_cfg.italicize
  end

  if agnosticdb.iff.is_enemy(person.name) then
    local enemy_cfg = config.enemies or {}
    if enemy_cfg.color and enemy_cfg.color ~= "" then
      style.color = enemy_cfg.color
    end
    if enemy_cfg.bold then style.bold = true end
    if enemy_cfg.underline then style.underline = true end
    if enemy_cfg.italicize then style.italicize = true end
  end

  if not style.color and not style.bold and not style.underline and not style.italicize then
    return nil
  end

  return style
end

function agnosticdb.highlights.reload()
  agnosticdb.highlights.clear()
  if not is_enabled() then return end
  if not agnosticdb.db.people then return end

  local ignored = highlight_ignore()
  local rows = db:fetch(agnosticdb.db.people)
  if not rows then return end

  agnosticdb.highlights.ids = agnosticdb.highlights.ids or {}
  for _, person in ipairs(rows) do
    local name = person.name
    if name and not ignored[name] then
      local style = style_for(person)
      if style then
        local id = tempTrigger(name, function()
          apply_style(name, style)
        end)
        agnosticdb.highlights.ids[name] = id
      end
    end
  end
end

function agnosticdb.highlights.clear()
  if not agnosticdb.highlights.ids then return end
  for _, id in pairs(agnosticdb.highlights.ids) do
    killTrigger(id)
  end
  agnosticdb.highlights.ids = {}
end

function agnosticdb.highlights.remove(name)
  if not agnosticdb.highlights.ids then return end
  local normalized = agnosticdb.db.normalize_name(name)
  if not normalized then return end
  local id = agnosticdb.highlights.ids[normalized]
  if id then
    killTrigger(id)
    agnosticdb.highlights.ids[normalized] = nil
  end
end

function agnosticdb.highlights.toggle(enabled)
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.highlights_enabled = enabled and true or false
  agnosticdb.config.save()
  if agnosticdb.conf.highlights_enabled then
    agnosticdb.highlights.reload()
  else
    agnosticdb.highlights.clear()
  end
end

function agnosticdb.highlights.ignore(name)
  local normalized = agnosticdb.db.normalize_name(name)
  if not normalized then return end
  local ignored = highlight_ignore()
  ignored[normalized] = true
  agnosticdb.config.save()
end

function agnosticdb.highlights.unignore(name)
  local normalized = agnosticdb.db.normalize_name(name)
  if not normalized then return end
  local ignored = highlight_ignore()
  ignored[normalized] = nil
  agnosticdb.config.save()
end

function agnosticdb.highlights.is_ignored(name)
  local normalized = agnosticdb.db.normalize_name(name)
  if not normalized then return false end
  local ignored = highlight_ignore()
  return ignored[normalized] == true
end
