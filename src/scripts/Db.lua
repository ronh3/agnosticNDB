agnosticdb = agnosticdb or {}

agnosticdb.db = agnosticdb.db or {}

local function normalize_name(name)
  if type(name) ~= "string" then return nil end
  if #name == 0 then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function db_conn()
  if not db or not db.__conn then return nil end
  return db.__conn[agnosticdb.db.name:lower()]
end

local function add_column_if_missing(row, column, sql)
  if row[column] ~= nil then return end
  local conn = db_conn()
  if not conn then return end
  conn:execute(sql)
  conn:commit()
end

function agnosticdb.db.init()
  if not db then
    decho("(agnosticdb): Mudlet DB API not available; database disabled.\n")
    return
  end

  agnosticdb.db.name = "agnosticdb"
  agnosticdb.db.schema = {
    people = {
      name = "",
      class = "",
      city = "",
      house = "",
      ["order"] = "",
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

  agnosticdb.db.handle = db:create("agnosticdb", agnosticdb.db.schema)
  agnosticdb.db.people = agnosticdb.db.handle.people

  local rows = db:fetch(agnosticdb.db.people)
  if not rows or not rows[1] then return end

  local sample = rows[1]
  add_column_if_missing(sample, "notes", [[ALTER TABLE people ADD COLUMN "notes" TEXT NULL DEFAULT ""]])
  add_column_if_missing(sample, "iff", [[ALTER TABLE people ADD COLUMN "iff" TEXT NULL DEFAULT "auto"]])
  add_column_if_missing(sample, "city_rank", [[ALTER TABLE people ADD COLUMN "city_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing(sample, "xp_rank", [[ALTER TABLE people ADD COLUMN "xp_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing(sample, "immortal", [[ALTER TABLE people ADD COLUMN "immortal" INTEGER NULL DEFAULT 0]])
  add_column_if_missing(sample, "dragon", [[ALTER TABLE people ADD COLUMN "dragon" INTEGER NULL DEFAULT 0]])
  add_column_if_missing(sample, "last_checked", [[ALTER TABLE people ADD COLUMN "last_checked" INTEGER NULL DEFAULT 0]])
  add_column_if_missing(sample, "source", [[ALTER TABLE people ADD COLUMN "source" TEXT NULL DEFAULT ""]])
end

function agnosticdb.db.get_person(name)
  if not agnosticdb.db.people then return nil end
  local normalized = normalize_name(name)
  if not normalized then return nil end
  local rows = db:fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.name, normalized))
  return rows and rows[1] or nil
end

function agnosticdb.db.upsert_person(fields)
  if not agnosticdb.db.people or type(fields) ~= "table" then return end

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

  db:merge_unique(agnosticdb.db.people, {record})
end

agnosticdb.db.normalize_name = normalize_name

function agnosticdb.db.delete_person(name)
  if not agnosticdb.db.people then return end
  local normalized = normalize_name(name)
  if not normalized then return end
  db:delete(agnosticdb.db.people, db:eq(agnosticdb.db.people.name, normalized))
end
