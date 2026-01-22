agnosticdb = agnosticdb or {}

agnosticdb.iff = agnosticdb.iff or {}

function agnosticdb.iff.set(name, status)
  -- status: "enemy", "ally", or "auto"
  agnosticdb.db.upsert_person({ name = name, iff = status })
end

function agnosticdb.iff.is_enemy(name)
  -- TODO: compute derived enemy status from politics + flags.
  local person = agnosticdb.db.get_person(name)
  return person and person.iff == "enemy" or false
end
