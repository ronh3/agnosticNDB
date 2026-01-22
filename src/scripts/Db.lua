agnosticdb = agnosticdb or {}

agnosticdb.db = agnosticdb.db or {}

local function db_prefix()
  return "<cyan>[agnosticdb]<reset> "
end

local function report_db_error(err)
  if agnosticdb.db.error_reported then return end
  agnosticdb.db.error_reported = true
  agnosticdb.db.disabled = true
  cecho(db_prefix() .. "Database error detected; disabling DB features.\n")
  cecho(db_prefix() .. string.format("Details: %s\n", tostring(err)))
  cecho(db_prefix() .. "Delete the agnosticdb database in your Mudlet profile and reload.\n")
end

local function normalize_name(name)
  if type(name) ~= "string" then return nil end
  if #name == 0 then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function db_conn()
  if not db or not db.__conn then return nil end
  return db.__conn[agnosticdb.db.name:lower()]
end

local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    report_db_error(result)
    return nil
  end
  return result
end

local function column_exists(column)
  local conn = db_conn()
  if not conn then return false end
  local cursor = conn:execute("PRAGMA table_info(people)")
  if not cursor then return false end
  local row = cursor:fetch({}, "a")
  while row do
    if row.name == column then
      if cursor.close then cursor:close() end
      return true
    end
    row = cursor:fetch({}, "a")
  end
  if cursor.close then cursor:close() end
  return false
end

local function add_column_if_missing(row, column, sql)
  if row and row[column] ~= nil then return end
  if column_exists(column) then return end
  local conn = db_conn()
  if not conn then return end
  conn:execute(sql)
  conn:commit()
end

function agnosticdb.db.ensure()
  if agnosticdb.db.disabled then return false end
  if agnosticdb.db.people then return true end
  if agnosticdb.db.init then
    agnosticdb.db.init()
  end
  return agnosticdb.db.people ~= nil and not agnosticdb.db.disabled
end

local function table_exists()
  local conn = db_conn()
  if not conn then return false end
  local cursor = conn:execute("SELECT name FROM sqlite_master WHERE type='table' AND name='people'")
  if not cursor then return false end
  local row = cursor:fetch({}, "a")
  if cursor.close then cursor:close() end
  return row and row.name == "people"
end

local function required_columns()
  return {
    "name",
    "class",
    "city",
    "house",
    "enemy_city",
    "enemy_house",
    "title",
    "notes",
    "iff",
    "city_rank",
    "xp_rank",
    "immortal",
    "dragon",
    "last_checked",
    "source"
  }
end

function agnosticdb.db.safe_fetch(tbl, clause)
  if agnosticdb.db.disabled then return nil end
  if not db or not tbl then return nil end
  return safe_call(db.fetch, db, tbl, clause)
end

function agnosticdb.db.check()
  agnosticdb.db.disabled = false
  agnosticdb.db.error_reported = false

  if not db then
    return false, {"Mudlet DB API unavailable."}
  end

  if not agnosticdb.db.ensure() then
    return false, {"Failed to initialize agnosticdb database."}
  end

  if not table_exists() then
    return false, {"Missing people table.", "Run adb dbreset or delete the DB file."}
  end

  local missing = {}
  for _, column in ipairs(required_columns()) do
    if not column_exists(column) then
      missing[#missing + 1] = column
    end
  end

  if #missing > 0 then
    return false, {"Missing columns: " .. table.concat(missing, ", "), "Run adb dbreset to rebuild schema."}
  end

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  if agnosticdb.db.disabled then
    return false, {"Database query failed. Run adb dbreset or delete the DB file."}
  end

  return true, {"Schema OK.", string.format("Rows: %d", rows and #rows or 0)}
end

function agnosticdb.db.reset()
  agnosticdb.db.disabled = false
  agnosticdb.db.error_reported = false

  if not db then
    return false, "Mudlet DB API unavailable."
  end

  local conn = db_conn()
  if not conn then
    return false, "DB connection unavailable."
  end

  local ok, err = pcall(conn.execute, conn, "DROP TABLE IF EXISTS people")
  if not ok then
    return false, err
  end
  if conn.commit then conn:commit() end

  agnosticdb.db.handle = nil
  agnosticdb.db.people = nil
  agnosticdb.db.init()
  if not agnosticdb.db.people then
    return false, "DB re-init failed."
  end

  return true
end

function agnosticdb.db.init()
  if not db then
    cecho("<yellow>(agnosticdb): Mudlet DB API not available; database disabled.<reset>\n")
    return
  end

  agnosticdb.db.name = "agnosticdb"
  agnosticdb.db.schema = {
    people = {
      name = "",
      class = "",
      city = "",
      house = "",
      enemy_city = "",
      enemy_house = "",
      title = "",
      notes = "",
      iff = "auto", -- enemy/ally/auto
      city_rank = -1,
      xp_rank = -1,
      immortal = 0,
      dragon = 0,
      last_checked = 0,
      source = "",

      _unique = {"name"},
      _violations = "REPLACE"
    }
  }

  agnosticdb.db.handle = safe_call(db.create, db, "agnosticdb", agnosticdb.db.schema)
  if not agnosticdb.db.handle then return end
  agnosticdb.db.people = agnosticdb.db.handle.people

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  local sample = rows and rows[1] or nil
  add_column_if_missing(sample, "notes", [[ALTER TABLE people ADD COLUMN "notes" TEXT NULL DEFAULT ""]])
  add_column_if_missing(sample, "iff", [[ALTER TABLE people ADD COLUMN "iff" TEXT NULL DEFAULT "auto"]])
  add_column_if_missing(sample, "enemy_city", [[ALTER TABLE people ADD COLUMN "enemy_city" TEXT NULL DEFAULT ""]])
  add_column_if_missing(sample, "enemy_house", [[ALTER TABLE people ADD COLUMN "enemy_house" TEXT NULL DEFAULT ""]])
  add_column_if_missing(sample, "city_rank", [[ALTER TABLE people ADD COLUMN "city_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing(sample, "xp_rank", [[ALTER TABLE people ADD COLUMN "xp_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing(sample, "immortal", [[ALTER TABLE people ADD COLUMN "immortal" INTEGER NULL DEFAULT 0]])
  add_column_if_missing(sample, "dragon", [[ALTER TABLE people ADD COLUMN "dragon" INTEGER NULL DEFAULT 0]])
  add_column_if_missing(sample, "last_checked", [[ALTER TABLE people ADD COLUMN "last_checked" INTEGER NULL DEFAULT 0]])
  add_column_if_missing(sample, "source", [[ALTER TABLE people ADD COLUMN "source" TEXT NULL DEFAULT ""]])
end

function agnosticdb.db.get_person(name)
  if not agnosticdb.db.ensure() then return nil end
  local normalized = normalize_name(name)
  if not normalized then return nil end
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.name, normalized))
  return rows and rows[1] or nil
end

function agnosticdb.db.upsert_person(fields)
  if not agnosticdb.db.ensure() or type(fields) ~= "table" then return end

  local normalized = normalize_name(fields.name)
  if not normalized then return end

  local record = {}
  for k, v in pairs(fields) do
    record[k] = v
  end
  record.name = normalized

  local existing = agnosticdb.db.get_person(normalized)
  if existing then
    for k, v in pairs(existing) do
      if record[k] == nil then
        record[k] = v
      end
    end
  end

  if not record.last_checked then
    record.last_checked = os.time()
  end

  safe_call(db.merge_unique, db, agnosticdb.db.people, {record})

  local updated = agnosticdb.db.get_person(normalized)
  if agnosticdb.highlights and agnosticdb.highlights.update then
    agnosticdb.highlights.update(updated)
  end
end

agnosticdb.db.normalize_name = normalize_name

function agnosticdb.db.delete_person(name)
  if not agnosticdb.db.ensure() then return end
  local normalized = normalize_name(name)
  if not normalized then return end
  safe_call(db.delete, db, agnosticdb.db.people, db:eq(agnosticdb.db.people.name, normalized))
  if agnosticdb.highlights and agnosticdb.highlights.remove then
    agnosticdb.highlights.remove(normalized)
  end
end
