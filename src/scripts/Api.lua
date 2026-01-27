agnosticdb = agnosticdb or {}

agnosticdb.api = agnosticdb.api or {}

local function api_url(name)
  return string.format("https://api.achaea.com/characters/%s.json", name)
end

local function list_url()
  return "https://api.achaea.com/characters.json"
end

local function trim_left(raw)
  local trimmed = (raw:gsub("^%s+", ""))
  if trimmed:sub(1, 3) == "\239\187\191" then
    trimmed = trimmed:sub(4)
  end
  return trimmed
end

local function strip_headers(raw)
  if type(raw) ~= "string" then return raw end
  local _, _, body = raw:find("\r\n\r\n(.*)")
  return body or raw
end

local function is_api_error_body(raw)
  if type(raw) ~= "string" then return false end
  local trimmed = trim_left(strip_headers(raw))
  if trimmed:find("Internal error", 1, true) then return true end
  if trimmed:find("<!DOCTYPE", 1, true) then return true end
  if trimmed:find("<html", 1, true) then return true end
  return false
end

local function titlecase(value)
  if type(value) ~= "string" then return "" end
  if value == "" then return "" end
  return value:sub(1, 1):upper() .. value:sub(2):lower()
end

local function normalize_city(value, title, existing)
  if type(value) ~= "string" then value = "" end
  if type(title) ~= "string" then title = "" end
  if type(existing) ~= "string" then existing = "" end

  if value == "" or value == "(none)" then
    if title == "Romeo, the Guide" or title == "Juliet, the Guide" then
      return "Divine"
    end
    return "Rogue"
  end

  if value == "(hidden)" then
    if existing ~= "" then
      return existing
    end
    return "Hidden"
  end

  return titlecase(value)
end

local function cache_dir()
  return getMudletHomeDir() .. "/agnosticdb"
end

local function ensure_cache_dir()
  if not lfs then return end
  local dir = cache_dir()
  if not lfs.attributes(dir) then
    lfs.mkdir(dir)
  end
end

local function list_cache_path()
  return cache_dir() .. "/characters.json"
end

local function chars_dir()
  return cache_dir() .. "/characters"
end

local function ensure_chars_dir()
  if not lfs then return end
  local dir = chars_dir()
  if not lfs.attributes(dir) then
    lfs.mkdir(dir)
  end
end

local function read_file(path)
  local handle = io.open(path, "rb")
  if not handle then return nil end
  local content = handle:read("*all")
  handle:close()
  return content
end

local function pick_body(a, b, c)
  local candidates = {a, b, c}
  local fallback

  for _, v in ipairs(candidates) do
    if type(v) == "string" then
      local stripped = strip_headers(v)
      local lead = trim_left(stripped):sub(1, 1)
      if lead == "{" or lead == "[" then
        return stripped
      end
      if not fallback then
        fallback = stripped
      end
    end
  end

  return fallback
end

local function decode_json(raw)
  if type(raw) ~= "string" then return nil end
  local trimmed = trim_left(strip_headers(raw))
  local lead = trimmed:sub(1, 1)
  if lead ~= "{" and lead ~= "[" then return nil end

  if json and type(json.decode) == "function" then
    local ok, value = pcall(json.decode, trimmed)
    if ok then return value end
  end
  if yajl and type(yajl.to_value) == "function" then
    local ok, value = pcall(yajl.to_value, trimmed)
    if ok then return value end
  end
  local ok, dk = pcall(require, "dkjson")
  if ok and dk and type(dk.decode) == "function" then
    local ok_decode, value = pcall(dk.decode, trimmed)
    if ok_decode then return value end
  end
  return nil
end

local function api_defaults()
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.api = agnosticdb.conf.api or {}
  if agnosticdb.conf.api.enabled == nil then agnosticdb.conf.api.enabled = true end
  agnosticdb.conf.api.min_refresh_hours = agnosticdb.conf.api.min_refresh_hours or 24
  agnosticdb.conf.api.backoff_seconds = agnosticdb.conf.api.backoff_seconds or 30
  agnosticdb.conf.api.min_interval_seconds = agnosticdb.conf.api.min_interval_seconds or 0
  agnosticdb.conf.api.timeout_seconds = agnosticdb.conf.api.timeout_seconds or 15
end

local function should_refresh(person)
  api_defaults()
  if not person or not person.last_checked then return true end
  local age = os.time() - person.last_checked
  return age >= (agnosticdb.conf.api.min_refresh_hours * 3600)
end

local function http_get(url, callback)
  if type(getHTTP) == "function" then
    local a, b, c = getHTTP(url)
    local body, code = a, b
    if type(a) == "boolean" and type(b) == "string" then
      body, code = b, c
    end
    body = pick_body(a, b, c) or body
    if type(callback) == "function" then
      callback(body, code)
    end
    return
  end

  if type(callback) == "function" then
    callback(nil, "http_unavailable")
  end
end

local function enqueue_callback(name, callback)
  agnosticdb.api.inflight = agnosticdb.api.inflight or {}
  agnosticdb.api.inflight[name] = agnosticdb.api.inflight[name] or {}
  table.insert(agnosticdb.api.inflight[name], callback)
end

local function resolve_callbacks(name, payload, err)
  if not agnosticdb.api.inflight or not agnosticdb.api.inflight[name] then return end
  for _, cb in ipairs(agnosticdb.api.inflight[name]) do
    if type(cb) == "function" then
      cb(payload, err)
    end
  end
  agnosticdb.api.inflight[name] = nil
end

local function extract_names(data)
  if type(data) ~= "table" then return {} end

  if type(data.characters) == "table" then data = data.characters end
  if type(data.names) == "table" then data = data.names end
  if type(data.list) == "table" then data = data.list end

  local names = {}
  local i = 1
  while data[i] do
    local entry = data[i]
    if type(entry) == "string" then
      names[#names + 1] = entry
    elseif type(entry) == "table" and entry.name then
      names[#names + 1] = entry.name
    end
    i = i + 1
  end

  return names
end

function agnosticdb.api.fetch_list(on_done)
  api_defaults()
  if not agnosticdb.conf.api.enabled then
    if type(on_done) == "function" then
      on_done(nil, "api_disabled")
    end
    return
  end

  agnosticdb.api.backoff_until = agnosticdb.api.backoff_until or 0
  if os.time() < agnosticdb.api.backoff_until then
    if type(on_done) == "function" then
      on_done(nil, "backoff")
    end
    return
  end

  local function finish_list(body)
    if type(body) ~= "string" or #body == 0 then
      return nil, "empty_response"
    end

    if is_api_error_body(body) then
      return nil, "api_error"
    end

    local data = decode_json(body)
    if type(data) ~= "table" then
      return nil, "decode_failed"
    end

    return extract_names(data), "ok"
  end

  local function try_download_fallback()
    if type(downloadFile) ~= "function" then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      if type(on_done) == "function" then
        on_done(nil, "decode_failed")
      end
      return
    end

    if agnosticdb.api.list_download_inflight then
      if type(on_done) == "function" then
        on_done(nil, "download_inflight")
      end
      return
    end

    ensure_cache_dir()
    local path = list_cache_path()
    agnosticdb.api.list_download_inflight = true

    local done_handler
    local error_handler

    done_handler = registerAnonymousEventHandler("sysDownloadDone", function(_, file)
      if file ~= path then return end
      killAnonymousEventHandler(done_handler)
      killAnonymousEventHandler(error_handler)
      agnosticdb.api.list_download_inflight = nil

      local content = read_file(path)
      if is_api_error_body(content) then
        agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
        if type(on_done) == "function" then
          on_done(nil, "api_error")
        end
        return
      end
      local names, status = finish_list(content)
      if status ~= "ok" then
        agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      end
      if type(on_done) == "function" then
        on_done(names, status)
      end
    end)

    error_handler = registerAnonymousEventHandler("sysDownloadError", function(_, file, err)
      if file ~= path then return end
      killAnonymousEventHandler(done_handler)
      killAnonymousEventHandler(error_handler)
      agnosticdb.api.list_download_inflight = nil
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      if type(on_done) == "function" then
        on_done(nil, err or "download_error")
      end
    end)

    downloadFile(path, list_url())
  end

  http_get(list_url(), function(body)
    local names, status = finish_list(body)
    if status == "ok" then
      agnosticdb.api.last_list_names = names
      agnosticdb.api.last_list_time = os.time()
      if type(on_done) == "function" then
        on_done(names, "ok")
      end
      return
    end

    try_download_fallback()
  end)
end

function agnosticdb.api.seed_names(names, source)
  if type(names) ~= "table" then return 0 end
  local count = 0
  for _, name in ipairs(names) do
    if not agnosticdb.db.get_person(name) then
      agnosticdb.db.upsert_person({
        name = name,
        source = source or "api_list",
        last_checked = 0
      })
      count = count + 1
    end
  end
  return count
end

function agnosticdb.api.queue_fetches(names, opts)
  if type(names) ~= "table" then return 0 end
  local count = 0
  for _, name in ipairs(names) do
    if agnosticdb.db.normalize_name(name) then
      agnosticdb.api.fetch(name, nil, opts)
      count = count + 1
    end
  end
  return count
end

function agnosticdb.api.fetch_online(on_done, opts)
  agnosticdb.api.fetch_list(function(names, status)
    if status ~= "ok" or type(names) ~= "table" then
      if type(on_done) == "function" then
        on_done(nil, status)
      end
      return
    end

    local added = agnosticdb.api.seed_names(names, "api_list")
    local queued = agnosticdb.api.queue_fetches(names, opts or { force = true })
    if type(on_done) == "function" then
      on_done({ names = names, added = added, queued = queued }, "ok")
    end
  end)
end

function agnosticdb.api.fetch_online_new(on_done, opts)
  agnosticdb.api.fetch_list(function(names, status)
    if status ~= "ok" or type(names) ~= "table" then
      if type(on_done) == "function" then
        on_done(nil, status)
      end
      return
    end

    local missing = {}
    for _, name in ipairs(names) do
      if not agnosticdb.db.get_person(name) then
        missing[#missing + 1] = name
      end
    end

    local added = agnosticdb.api.seed_names(missing, "api_list")
    local queued = agnosticdb.api.queue_fetches(missing, opts or { force = true })
    if type(on_done) == "function" then
      on_done({ names = names, missing = missing, added = added, queued = queued }, "ok")
    end
  end)
end

function agnosticdb.api.update_all(on_done, opts)
  if not agnosticdb.db.people then
    if type(on_done) == "function" then
      on_done(nil, "db_unavailable")
    end
    return
  end

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  if not rows then
    if type(on_done) == "function" then
      on_done(nil, "db_empty")
    end
    return
  end

  local names = {}
  for _, row in ipairs(rows) do
    if row.name then
      names[#names + 1] = row.name
    end
  end

  local queued = agnosticdb.api.queue_fetches(names, opts or { force = true })
  if type(on_done) == "function" then
    on_done({ count = #names, queued = queued }, "ok")
  end
end

function agnosticdb.api.estimate_queue_seconds(extra)
  api_defaults()
  local queue_len = 0
  if agnosticdb.api.queue then
    queue_len = #agnosticdb.api.queue
  end
  local total = queue_len + (extra or 0)
  if total <= 0 then return 0 end

  local base = total * agnosticdb.conf.api.min_interval_seconds
  local now = os.time()
  local delay = 0

  local last = agnosticdb.api.last_request_time or 0
  local since = now - last
  if since < agnosticdb.conf.api.min_interval_seconds then
    delay = agnosticdb.conf.api.min_interval_seconds - since
  end

  local backoff_until = agnosticdb.api.backoff_until or 0
  if backoff_until > now then
    delay = delay + (backoff_until - now)
  end

  return base + delay
end

local function perform_fetch(name, on_finished)
  local person = agnosticdb.db.get_person(name)

  local finished = false
  local timeout_timer = nil

  local function finish(payload, status)
    if finished then return end
    finished = true
    if timeout_timer then killTimer(timeout_timer) end
    resolve_callbacks(name, payload, status)
    if type(on_finished) == "function" then
      on_finished()
    end
  end

  local timeout = agnosticdb.conf and agnosticdb.conf.api and agnosticdb.conf.api.timeout_seconds or 15
  if timeout > 0 then
    timeout_timer = tempTimer(timeout, function()
      if finished then return end
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      finish(person, "timeout")
    end)
  end

  local function resolve_record(data)
    local title = data.fullname or ""
    local city = normalize_city(data.city or "", title, person and person.city or "")
    local class = titlecase(data.class or "")
    local house = titlecase(data.house or "")

    local record = {
      name = data.name or name,
      class = class,
      city = city,
      house = house,
      title = title,
      xp_rank = data.xp_rank or -1,
      level = data.level or -1,
      source = "api",
      last_checked = os.time()
    }

    if agnosticdb.conf and agnosticdb.conf.prune_dormant and record.xp_rank == 0 and city ~= "Divine" then
      agnosticdb.db.delete_person(record.name)
      if agnosticdb.highlights and agnosticdb.highlights.remove then
        agnosticdb.highlights.remove(record.name)
      end
      finish(nil, "pruned")
      return
    end

    agnosticdb.db.upsert_person(record)
    local updated = agnosticdb.db.get_person(name)
    if agnosticdb.highlights and agnosticdb.highlights.update then
      agnosticdb.highlights.update(updated)
    end
    finish(updated, "ok")
  end

  local function download_fallback()
    if type(downloadFile) ~= "function" then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      finish(person, "decode_failed")
      return
    end

    agnosticdb.api.download_inflight = agnosticdb.api.download_inflight or {}
    if agnosticdb.api.download_inflight[name] then return end
    agnosticdb.api.download_inflight[name] = true

    ensure_cache_dir()
    ensure_chars_dir()
    local path = chars_dir() .. "/" .. name .. ".json"

    local done_handler
    local error_handler

    done_handler = registerAnonymousEventHandler("sysDownloadDone", function(_, file)
      if file ~= path then return end
      killAnonymousEventHandler(done_handler)
      killAnonymousEventHandler(error_handler)
      agnosticdb.api.download_inflight[name] = nil

      local content = read_file(path)
      if is_api_error_body(content) then
        agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
        finish(person, "api_error")
        return
      end
      local data = decode_json(content)
      if type(data) ~= "table" then
        agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
        finish(person, "decode_failed")
        return
      end

      resolve_record(data)
    end)

    error_handler = registerAnonymousEventHandler("sysDownloadError", function(_, file, err)
      if file ~= path then return end
      killAnonymousEventHandler(done_handler)
      killAnonymousEventHandler(error_handler)
      agnosticdb.api.download_inflight[name] = nil
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      finish(person, err or "download_error")
    end)

    downloadFile(path, api_url(name))
  end

  http_get(api_url(name), function(body, code)
    if type(body) ~= "string" or #body == 0 then
      download_fallback()
      return
    end

    if is_api_error_body(body) then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      finish(person, "api_error")
      return
    end

    local data = decode_json(body)
    if type(data) ~= "table" then
      download_fallback()
      return
    end

    resolve_record(data)
  end)
end

local function start_queue()
  agnosticdb.api.queue = agnosticdb.api.queue or {}
  agnosticdb.api.queued = agnosticdb.api.queued or {}
  if agnosticdb.api.queue_running then return end
  agnosticdb.api.queue_running = true
  agnosticdb.api.queue_stats = {
    ok = 0,
    cached = 0,
    pruned = 0,
    api_error = 0,
    decode_failed = 0,
    download_error = 0,
    other = 0,
    started_at = os.time(),
    processed = 0,
    total = #agnosticdb.api.queue,
    milestones = { [25] = false, [50] = false, [75] = false }
  }

  local function step()
    if #agnosticdb.api.queue == 0 then
      agnosticdb.api.queue_running = false
      if agnosticdb.api.queue_stats then
        agnosticdb.api.queue_stats.finished_at = os.time()
        agnosticdb.api.queue_stats.elapsed_seconds = agnosticdb.api.queue_stats.finished_at - agnosticdb.api.queue_stats.started_at
      end
      if type(agnosticdb.api.on_queue_done) == "function" then
        agnosticdb.api.on_queue_done(agnosticdb.api.queue_stats)
      end
      return
    end

    agnosticdb.api.backoff_until = agnosticdb.api.backoff_until or 0
    local now = os.time()
    local delay = 0

    local last = agnosticdb.api.last_request_time or 0
    local since = now - last
    if since < agnosticdb.conf.api.min_interval_seconds then
      delay = agnosticdb.conf.api.min_interval_seconds - since
    end

    if agnosticdb.api.backoff_until > now then
      local backoff_delay = agnosticdb.api.backoff_until - now
      if backoff_delay > delay then delay = backoff_delay end
    end

    if delay > 0 then
      tempTimer(delay, step)
      return
    end

    local next_name = table.remove(agnosticdb.api.queue, 1)
    agnosticdb.api.queued[next_name] = nil
    agnosticdb.api.last_request_time = os.time()

    if next_name then
      perform_fetch(next_name, step)
      return
    end

    tempTimer(0, step)
  end

  step()
end

function agnosticdb.api.fetch(name, on_done, opts)
  api_defaults()
  if not agnosticdb.conf.api.enabled then
    if type(on_done) == "function" then
      on_done(nil, "api_disabled")
    end
    return
  end

  local normalized = agnosticdb.db.normalize_name(name)
  if not normalized then
    if type(on_done) == "function" then
      on_done(nil, "invalid_name")
    end
    return
  end

  local person = agnosticdb.db.get_person(normalized)
  if person and not (opts and opts.force) and not should_refresh(person) then
    if type(on_done) == "function" then
      on_done(person, "cached")
    end
    return
  end

  if agnosticdb.api.inflight and agnosticdb.api.inflight[normalized] then
    enqueue_callback(normalized, on_done)
    return
  end

  local function wrapped(person_result, status)
    local stats = agnosticdb.api.queue_stats
    if stats then
      if status == "ok" then
        stats.ok = stats.ok + 1
      elseif status == "cached" then
        stats.cached = stats.cached + 1
      elseif status == "pruned" then
        stats.pruned = stats.pruned + 1
      elseif status == "api_error" then
        stats.api_error = stats.api_error + 1
      elseif status == "decode_failed" then
        stats.decode_failed = stats.decode_failed + 1
      elseif status == "download_error" then
        stats.download_error = stats.download_error + 1
      else
        stats.other = stats.other + 1
      end
      stats.processed = stats.processed + 1
      if stats.total and stats.total > 0 then
        local percent = math.floor((stats.processed / stats.total) * 100)
        for _, threshold in ipairs({25, 50, 75}) do
          if percent >= threshold and not stats.milestones[threshold] then
            stats.milestones[threshold] = true
            if type(agnosticdb.api.on_queue_progress) == "function" then
              agnosticdb.api.on_queue_progress(threshold, stats)
            end
          end
        end
      end
    end
    if type(on_done) == "function" then
      on_done(person_result, status)
    end
  end

  enqueue_callback(normalized, wrapped)

  agnosticdb.api.queue = agnosticdb.api.queue or {}
  agnosticdb.api.queued = agnosticdb.api.queued or {}
  if not agnosticdb.api.queued[normalized] then
    table.insert(agnosticdb.api.queue, normalized)
    agnosticdb.api.queued[normalized] = true
    if agnosticdb.api.queue_running and agnosticdb.api.queue_stats then
      agnosticdb.api.queue_stats.total = agnosticdb.api.queue_stats.total + 1
    end
  end

  start_queue()
end

agnosticdb.api.url_for = api_url

function agnosticdb.api.cancel_queue()
  local pending = agnosticdb.api.queue and #agnosticdb.api.queue or 0
  agnosticdb.api.queue = {}
  agnosticdb.api.queued = {}
  agnosticdb.api.queue_running = false
  agnosticdb.api.queue_stats = nil
  agnosticdb.api.on_queue_done = nil
  return pending
end
