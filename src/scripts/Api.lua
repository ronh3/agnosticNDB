agnosticdb = agnosticdb or {}

agnosticdb.api = agnosticdb.api or {}

local function api_url(name)
  return string.format("https://api.achaea.com/characters/%s.json", name)
end

local function list_url()
  return "https://api.achaea.com/characters.json"
end

local function trim_left(raw)
  return (raw:gsub("^%s+", ""))
end

local function decode_json(raw)
  if type(raw) ~= "string" then return nil end
  local trimmed = trim_left(raw)
  local lead = trimmed:sub(1, 1)
  if lead ~= "{" and lead ~= "[" then return nil end

  if json and type(json.decode) == "function" then
    local ok, value = pcall(json.decode, raw)
    if ok then return value end
  end
  if yajl and type(yajl.to_value) == "function" then
    local ok, value = pcall(yajl.to_value, raw)
    if ok then return value end
  end
  local ok, dk = pcall(require, "dkjson")
  if ok and dk and type(dk.decode) == "function" then
    local ok_decode, value = pcall(dk.decode, raw)
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

  http_get(list_url(), function(body)
    if type(body) ~= "string" or #body == 0 then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      if type(on_done) == "function" then
        on_done(nil, "empty_response")
      end
      return
    end

    local data = decode_json(body)
    if type(data) ~= "table" then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      if type(on_done) == "function" then
        on_done(nil, "decode_failed")
      end
      return
    end

    local names = extract_names(data)
    if type(on_done) == "function" then
      on_done(names, "ok")
    end
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

function agnosticdb.api.fetch(name, on_done)
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
  if person and not should_refresh(person) then
    if type(on_done) == "function" then
      on_done(person, "cached")
    end
    return
  end

  agnosticdb.api.backoff_until = agnosticdb.api.backoff_until or 0
  if os.time() < agnosticdb.api.backoff_until then
    if type(on_done) == "function" then
      on_done(person, "backoff")
    end
    return
  end

  if agnosticdb.api.inflight and agnosticdb.api.inflight[normalized] then
    enqueue_callback(normalized, on_done)
    return
  end

  enqueue_callback(normalized, on_done)

  http_get(api_url(normalized), function(body, code)
    if type(body) ~= "string" or #body == 0 then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      resolve_callbacks(normalized, person, "empty_response")
      return
    end

    local data = decode_json(body)
    if type(data) ~= "table" then
      agnosticdb.api.backoff_until = os.time() + agnosticdb.conf.api.backoff_seconds
      resolve_callbacks(normalized, person, "decode_failed")
      return
    end

    local record = {
      name = data.name or normalized,
      class = data.class or "",
      city = data.city or "",
      house = data.house or "",
      title = data.fullname or "",
      xp_rank = data.xp_rank or -1,
      source = "api",
      last_checked = os.time()
    }

    agnosticdb.db.upsert_person(record)
    resolve_callbacks(normalized, agnosticdb.db.get_person(normalized), "ok")
  end)
end

agnosticdb.api.url_for = api_url
