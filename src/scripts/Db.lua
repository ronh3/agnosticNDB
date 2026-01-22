agnosticdb = agnosticdb or {}

agnosticdb.db = agnosticdb.db or {}

function agnosticdb.db.init()
  agnosticdb.db.name = "agnosticdb"
  -- TODO: initialize schema with Mudlet's db API.
end

function agnosticdb.db.get_person(name)
  -- TODO: fetch person by name.
  return nil
end

function agnosticdb.db.upsert_person(fields)
  -- TODO: merge/update person record.
end
