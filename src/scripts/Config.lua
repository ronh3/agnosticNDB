agnosticdb = agnosticdb or {}

agnosticdb.config = agnosticdb.config or {}

local function config_dir()
  return getMudletHomeDir() .. "/agnosticdb"
end

local function config_path()
  return config_dir() .. "/config"
end

local function ensure_dir()
  if not lfs then return end
  local dir = config_dir()
  if not lfs.attributes(dir) then
    lfs.mkdir(dir)
  end
end

function agnosticdb.config.load()
  agnosticdb.conf = agnosticdb.conf or {
    politics = {},
    highlight_ignore = {},
    api = { enabled = true, min_refresh_hours = 24 }
  }

  if type(table.load) ~= "function" then return end

  local ok, data = pcall(function()
    local t = {}
    if lfs and lfs.attributes(config_path()) then
      table.load(config_path(), t)
    end
    return t
  end)

  if ok and type(data) == "table" then
    for k, v in pairs(data) do
      agnosticdb.conf[k] = v
    end
  end

  agnosticdb.conf.api = agnosticdb.conf.api or { enabled = true, min_refresh_hours = 24 }
  if agnosticdb.conf.api.enabled == nil then agnosticdb.conf.api.enabled = true end
  agnosticdb.conf.api.min_refresh_hours = agnosticdb.conf.api.min_refresh_hours or 24
  agnosticdb.conf.api.backoff_seconds = agnosticdb.conf.api.backoff_seconds or 30
  agnosticdb.conf.api.min_interval_seconds = agnosticdb.conf.api.min_interval_seconds or 0
  agnosticdb.conf.api.timeout_seconds = agnosticdb.conf.api.timeout_seconds or 15
  if agnosticdb.conf.api.announce_changes_only == nil then
    agnosticdb.conf.api.announce_changes_only = false
  end

  agnosticdb.conf.theme = agnosticdb.conf.theme or {}
  if agnosticdb.conf.theme.auto_city == nil then
    agnosticdb.conf.theme.auto_city = true
  end
  agnosticdb.conf.theme.name = agnosticdb.conf.theme.name or ""
  agnosticdb.conf.theme.custom = agnosticdb.conf.theme.custom or {
    accent = "cyan",
    border = "grey",
    text = "white",
    muted = "light_grey"
  }
  agnosticdb.conf.theme.customs = agnosticdb.conf.theme.customs or {}
  agnosticdb.conf.honors = agnosticdb.conf.honors or { delay_seconds = 2 }
  agnosticdb.conf.honors.delay_seconds = agnosticdb.conf.honors.delay_seconds or 2

  if agnosticdb.conf.highlights_enabled == nil then
    agnosticdb.conf.highlights_enabled = true
  end

  agnosticdb.conf.colors = agnosticdb.conf.colors or { enemy = "red", ally = "green" }
  agnosticdb.conf.highlight_ignore = agnosticdb.conf.highlight_ignore or {}
  agnosticdb.conf.prune_dormant = agnosticdb.conf.prune_dormant or false
  agnosticdb.conf.ui = agnosticdb.conf.ui or {}
  if agnosticdb.conf.ui.quiet_mode == nil then
    agnosticdb.conf.ui.quiet_mode = false
  end

  agnosticdb.conf.highlight = agnosticdb.conf.highlight or {
    enemies = { color = "", bold = false, underline = true, italicize = true, enabled = true, require_personal = false },
    cities = {
      ashtan = { color = "purple", bold = false, underline = false, italicize = false },
      cyrene = { color = "cornflower_blue", bold = false, underline = false, italicize = false },
      eleusis = { color = "forest_green", bold = false, underline = false, italicize = false },
      hashan = { color = "yellow", bold = false, underline = false, italicize = false },
      mhaldor = { color = "red", bold = false, underline = false, italicize = false },
      targossas = { color = "white", bold = false, underline = false, italicize = false },
      rogue = { color = "orange", bold = false, underline = false, italicize = false },
      divine = { color = "pink", bold = true, underline = false, italicize = true },
      hidden = { color = "green", bold = true, underline = false, italicize = true },
    }
  }
end

function agnosticdb.config.save()
  if type(table.save) ~= "function" then return end
  ensure_dir()
  agnosticdb.conf = agnosticdb.conf or {}
  table.save(config_path(), agnosticdb.conf)
end

local function is_abs(path)
  if not path or path == "" then return false end
  if path:match("^/") then return true end
  if path:match("^[A-Za-z]:[\\/]") then return true end
  return false
end

local function normalize_path(path)
  if not path or path == "" then return nil end
  local normalized = path
  if not normalized:find("%.json$") then
    normalized = normalized .. ".json"
  end
  if is_abs(normalized) then
    return normalized
  end
  return config_dir() .. "/" .. normalized
end

local function can_json()
  return yajl and type(yajl.to_string) == "function" and type(yajl.to_value) == "function"
end

local function config_snapshot()
  local conf = agnosticdb.conf or {}
  return {
    api = {
      enabled = conf.api and conf.api.enabled,
      min_refresh_hours = conf.api and conf.api.min_refresh_hours,
      min_interval_seconds = conf.api and conf.api.min_interval_seconds,
      backoff_seconds = conf.api and conf.api.backoff_seconds,
      timeout_seconds = conf.api and conf.api.timeout_seconds,
      announce_changes_only = conf.api and conf.api.announce_changes_only
    },
    honors = {
      delay_seconds = conf.honors and conf.honors.delay_seconds
    },
    theme = {
      name = conf.theme and conf.theme.name,
      auto_city = conf.theme and conf.theme.auto_city,
      custom = conf.theme and conf.theme.custom,
      customs = conf.theme and conf.theme.customs
    },
    highlights_enabled = conf.highlights_enabled,
    highlight = conf.highlight,
    highlight_ignore = conf.highlight_ignore,
    prune_dormant = conf.prune_dormant,
    ui = {
      quiet_mode = conf.ui and conf.ui.quiet_mode
    }
  }
end

local function merge_into(dest, src)
  if type(dest) ~= "table" or type(src) ~= "table" then return end
  for k, v in pairs(src) do
    dest[k] = v
  end
end

function agnosticdb.config.export_settings(path)
  if not can_json() then
    return nil, "json_unavailable"
  end
  ensure_dir()
  local output_path = path
  if not output_path or output_path == "" then
    output_path = config_dir() .. "/agnosticdb_config.json"
  else
    output_path = normalize_path(output_path)
  end

  local payload = {
    version = 1,
    exported_at = os.time(),
    config = config_snapshot()
  }

  local ok, encoded = pcall(yajl.to_string, payload)
  if not ok then
    return nil, "encode_failed"
  end

  local file, err = io.open(output_path, "w")
  if not file then
    return nil, "io_error:" .. tostring(err)
  end
  file:write(encoded)
  file:close()

  return { path = output_path }
end

function agnosticdb.config.import_settings(path)
  if not can_json() then
    return nil, "json_unavailable"
  end
  if not path or path == "" then
    return nil, "path_required"
  end

  local input_path = normalize_path(path)
  local file, err = io.open(input_path, "r")
  if not file then
    return nil, "io_error:" .. tostring(err)
  end
  local content = file:read("*a")
  file:close()

  local ok, data = pcall(yajl.to_value, content)
  if not ok or type(data) ~= "table" then
    return nil, "decode_failed"
  end

  local payload = data.config or data
  if type(payload) ~= "table" then
    return nil, "invalid_format"
  end

  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.api = agnosticdb.conf.api or {}
  agnosticdb.conf.honors = agnosticdb.conf.honors or {}
  agnosticdb.conf.theme = agnosticdb.conf.theme or {}
  agnosticdb.conf.highlight = agnosticdb.conf.highlight or { enemies = {}, cities = {} }
  agnosticdb.conf.highlight.enemies = agnosticdb.conf.highlight.enemies or {}
  agnosticdb.conf.highlight.cities = agnosticdb.conf.highlight.cities or {}
  agnosticdb.conf.highlight_ignore = agnosticdb.conf.highlight_ignore or {}
  agnosticdb.conf.ui = agnosticdb.conf.ui or {}

  if type(payload.api) == "table" then
    merge_into(agnosticdb.conf.api, payload.api)
  end
  if type(payload.honors) == "table" then
    merge_into(agnosticdb.conf.honors, payload.honors)
  end
  if type(payload.theme) == "table" then
    if payload.theme.name ~= nil then agnosticdb.conf.theme.name = payload.theme.name end
    if payload.theme.auto_city ~= nil then agnosticdb.conf.theme.auto_city = payload.theme.auto_city end
    if type(payload.theme.custom) == "table" then
      agnosticdb.conf.theme.custom = payload.theme.custom
    end
    if type(payload.theme.customs) == "table" then
      agnosticdb.conf.theme.customs = payload.theme.customs
    end
  end
  if payload.highlights_enabled ~= nil then
    agnosticdb.conf.highlights_enabled = payload.highlights_enabled
  end
  if payload.prune_dormant ~= nil then
    agnosticdb.conf.prune_dormant = payload.prune_dormant
  end
  if type(payload.ui) == "table" and payload.ui.quiet_mode ~= nil then
    agnosticdb.conf.ui.quiet_mode = payload.ui.quiet_mode
  end
  if type(payload.highlight) == "table" then
    if type(payload.highlight.enemies) == "table" then
      merge_into(agnosticdb.conf.highlight.enemies, payload.highlight.enemies)
    end
    if type(payload.highlight.cities) == "table" then
      for city, style in pairs(payload.highlight.cities) do
        agnosticdb.conf.highlight.cities[city] = agnosticdb.conf.highlight.cities[city] or {}
        if type(style) == "table" then
          merge_into(agnosticdb.conf.highlight.cities[city], style)
        end
      end
    end
  end
  if type(payload.highlight_ignore) == "table" then
    agnosticdb.conf.highlight_ignore = payload.highlight_ignore
  end

  agnosticdb.config.save()
  if agnosticdb.highlights and agnosticdb.highlights.reload then
    agnosticdb.highlights.reload()
  end

  return { path = input_path }
end
