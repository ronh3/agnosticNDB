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
  agnosticdb.conf.honors = agnosticdb.conf.honors or { delay_seconds = 2 }
  agnosticdb.conf.honors.delay_seconds = agnosticdb.conf.honors.delay_seconds or 2

  if agnosticdb.conf.highlights_enabled == nil then
    agnosticdb.conf.highlights_enabled = true
  end

  agnosticdb.conf.colors = agnosticdb.conf.colors or { enemy = "red", ally = "green" }
  agnosticdb.conf.highlight_ignore = agnosticdb.conf.highlight_ignore or {}
  agnosticdb.conf.prune_dormant = agnosticdb.conf.prune_dormant or false

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
