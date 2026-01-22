agnosticdb = agnosticdb or {}

agnosticdb.api = agnosticdb.api or {}

local function api_url(name)
  return string.format("https://api.achaea.com/characters/%s.json", name)
end

function agnosticdb.api.fetch(name, on_done)
  -- TODO: implement HTTP GET, cache, and backoff.
  if type(on_done) == "function" then
    on_done(nil, "not implemented")
  end
end

agnosticdb.api.url_for = api_url
