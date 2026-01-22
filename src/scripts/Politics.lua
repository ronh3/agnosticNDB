agnosticdb = agnosticdb or {}

agnosticdb.politics = agnosticdb.politics or {}

agnosticdb.politics.cities = {
  "Ashtan",
  "Cyrene",
  "Eleusis",
  "Hashan",
  "Mhaldor",
  "Targossas"
}

local function normalize_city(city)
  if type(city) ~= "string" then return nil end
  if #city == 0 then return nil end
  return city:sub(1, 1):upper() .. city:sub(2):lower()
end

function agnosticdb.politics.set_city_relation(city, relation)
  local normalized = normalize_city(city)
  if not normalized then return end
  if relation ~= "enemy" and relation ~= "ally" and relation ~= "neutral" then return end
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.politics = agnosticdb.conf.politics or {}
  agnosticdb.conf.politics[normalized] = relation
  agnosticdb.config.save()
end

function agnosticdb.politics.get_city_relation(city)
  local normalized = normalize_city(city)
  if not normalized then return "neutral" end
  agnosticdb.conf = agnosticdb.conf or {}
  local politics = agnosticdb.conf.politics or {}
  return politics[normalized] or "neutral"
end

function agnosticdb.politics.toggle_city_relation(city)
  local current = agnosticdb.politics.get_city_relation(city)
  local next_value = "neutral"
  if current == "neutral" then
    next_value = "enemy"
  elseif current == "enemy" then
    next_value = "ally"
  elseif current == "ally" then
    next_value = "neutral"
  end
  agnosticdb.politics.set_city_relation(city, next_value)
end

agnosticdb.politics.normalize_city = normalize_city
