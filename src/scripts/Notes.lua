agnosticdb = agnosticdb or {}

agnosticdb.notes = agnosticdb.notes or {}

function agnosticdb.notes.set(name, notes)
  agnosticdb.db.upsert_person({ name = name, notes = notes })
end

function agnosticdb.notes.get(name)
  local person = agnosticdb.db.get_person(name)
  return person and person.notes or nil
end
