agnosticdb = agnosticdb or {}

agnosticdb.iff = agnosticdb.iff or {}

function agnosticdb.iff.set(name, status)
  -- status: "enemy", "ally", or "auto"
  agnosticdb.db.upsert_person({ name = name, iff = status })
end

function agnosticdb.iff.is_enemy(name)
  local person = agnosticdb.db.get_person(name)
  if not person then return false end

  if person.iff == "enemy" then return true end
  if person.iff == "ally" then return false end

  if type(person.enemy_city) == "string" and person.enemy_city ~= "" then
    return true
  end
  if type(person.enemy_house) == "string" and person.enemy_house ~= "" then
    return true
  end

  local city = person.city
  if type(city) ~= "string" or city == "" then return false end

  return agnosticdb.politics.get_city_relation(city) == "enemy"
end
