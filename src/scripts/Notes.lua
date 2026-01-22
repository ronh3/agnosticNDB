agnosticdb = agnosticdb or {}

agnosticdb.notes = agnosticdb.notes or {}

function agnosticdb.notes.set(name, notes)
  agnosticdb.db.upsert_person({ name = name, notes = notes })
end

function agnosticdb.notes.get(name)
  local person = agnosticdb.db.get_person(name)
  return person and person.notes or nil
end

function agnosticdb.notes.clear(name)
  agnosticdb.db.upsert_person({ name = name, notes = "" })
end

function agnosticdb.notes.clear_all()
  if not agnosticdb.db.people then return 0 end
  local rows = db:fetch(agnosticdb.db.people)
  if not rows or #rows == 0 then return 0 end

  local count = 0
  for _, row in ipairs(rows) do
    if row.notes and row.notes ~= "" then
      agnosticdb.db.upsert_person({ name = row.name, notes = "" })
      count = count + 1
    end
  end
  return count
end
