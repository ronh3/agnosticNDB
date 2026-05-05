local M = {}

local function root()
  return assert(os.getenv("TESTS_DIRECTORY"), "TESTS_DIRECTORY env var is required")
end

local function reset_table_data(tbl)
  if type(tbl) ~= "table" then
    return
  end

  for key, value in pairs(tbl) do
    if type(value) ~= "function" then
      tbl[key] = nil
    end
  end
end

local function remove_config_files()
  if type(getMudletHomeDir) ~= "function" then
    return
  end

  local base = getMudletHomeDir() .. "/agnosticdb"
  os.remove(base .. "/config")
  os.remove(base .. "/agnosticdb_config.json")
end

local function reset_db()
  if not agnosticdb or not agnosticdb.db then
    return
  end

  agnosticdb.db.disabled = nil
  agnosticdb.db.error_reported = nil
  pcall(function() agnosticdb.db.init() end)
  pcall(function() agnosticdb.db.reset() end)
  pcall(function() agnosticdb.db.init() end)
end

function M.load()
  return M
end

function M.reset()
  assert(agnosticdb, "agnosticdb package is not loaded")

  if agnosticdb.highlights and agnosticdb.highlights.clear then
    pcall(agnosticdb.highlights.clear)
  end

  remove_config_files()

  agnosticdb.conf = nil
  agnosticdb._echo_line_pending = nil
  if agnosticdb.ui then
    agnosticdb.ui._frame_open = nil
    agnosticdb.ui._frame_seq = nil
  end

  reset_table_data(agnosticdb.api)
  reset_table_data(agnosticdb.honors)
  reset_table_data(agnosticdb.highlights)

  if agnosticdb.config and agnosticdb.config.load then
    agnosticdb.config.load()
  end

  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.api = agnosticdb.conf.api or {}
  agnosticdb.conf.api.enabled = true
  agnosticdb.conf.api.min_refresh_hours = 24
  agnosticdb.conf.api.min_interval_seconds = 0
  agnosticdb.conf.api.backoff_seconds = 0
  agnosticdb.conf.api.timeout_seconds = 0
  agnosticdb.conf.api.announce_changes_only = false
  agnosticdb.conf.honors = agnosticdb.conf.honors or {}
  agnosticdb.conf.honors.delay_seconds = 0
  agnosticdb.conf.highlight_ignore = {}
  agnosticdb.conf.politics = {}
  agnosticdb.conf.highlights_enabled = false
  agnosticdb.conf.ui = agnosticdb.conf.ui or {}
  agnosticdb.conf.ui.quiet_mode = false
  agnosticdb.conf.ui.frames_enabled = true

  reset_db()

  agnosticdb.api.queue = {}
  agnosticdb.api.queued = {}
  agnosticdb.api.inflight = {}
  agnosticdb.api.download_inflight = {}
  agnosticdb.api.queue_running = false
  agnosticdb.api.queue_stats = nil
  agnosticdb.api.on_queue_done = nil
  agnosticdb.api.on_queue_progress = nil
  agnosticdb.api.backoff_until = 0
  agnosticdb.api.last_request_time = 0
  agnosticdb.api.last_list_time = 0
  agnosticdb.api.last_prune_at = 0
  agnosticdb.api.last_prune_count = 0

  agnosticdb.honors.active = nil
  agnosticdb.honors.queue = {}
  agnosticdb.honors.queue_running = false
  agnosticdb.honors.queue_stats = nil
  agnosticdb.honors.queue_on_done = nil
  agnosticdb.honors.queue_opts = nil

  agnosticdb.highlights.ids = {}

  return agnosticdb
end

function M.support_path(path)
  return root() .. "/" .. path
end

return M
