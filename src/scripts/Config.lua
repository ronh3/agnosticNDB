agnosticdb = agnosticdb or {}

agnosticdb.config = agnosticdb.config or {}

local function config_path()
  return getMudletHomeDir() .. "/agnosticdb/config"
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
end

function agnosticdb.config.save()
  if type(table.save) ~= "function" then return end
  agnosticdb.conf = agnosticdb.conf or {}
  table.save(config_path(), agnosticdb.conf)
end
