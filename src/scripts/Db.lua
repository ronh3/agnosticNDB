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

local function safe_call(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    report_db_error(result)
    return nil
  end
  return result
end

local function trim(value)
  if type(value) ~= "string" then return "" end
  return value:gsub("^%s+", ""):gsub("%s+$", "")
end

local function titlecase_words(value)
  if type(value) ~= "string" then return "" end
  if value == "" then return "" end
  return value:gsub("(%a)([%w']*)", function(a, b)
    return a:upper() .. b:lower()
  end)
end

local reserved_names = {
  all = true,
  online = true,
}

local function is_valid_person_name(name)
  if type(name) ~= "string" then return false end
  local value = trim(name)
  if value == "" then return false end
  local lower = value:lower()
  if reserved_names[lower] then return false end
  return value:match("^[A-Za-z][A-Za-z'%-]*$") ~= nil
end

local function normalize_name(name)
  if not is_valid_person_name(name) then return nil end
  local value = trim(name)
  return value:sub(1, 1):upper() .. value:sub(2):lower()
end

local base_races = {
  atavian = "Atavian",
  dwarf = "Dwarf",
  fayad = "Fayad",
  grook = "Grook",
  horkval = "Horkval",
  human = "Human",
  mhun = "Mhun",
  rajamala = "Rajamala",
  satyr = "Satyr",
  siren = "Siren",
  ["tash'la"] = "Tash'la",
  ["tsol'aa"] = "Tsol'aa",
  troll = "Troll",
  xoran = "Xoran",
}

local function canonical_base_race(value)
  if type(value) ~= "string" then return "" end
  local key = trim(value):lower()
  if key == "" then return "" end
  return base_races[key] or titlecase_words(key)
end

local function detect_current_form(value)
  if type(value) ~= "string" then return "" end
  local lower = trim(value):lower()
  if lower == "" then return "" end
  if lower:find("%f[%a]dragon%f[%A]") then
    return "Dragon"
  end
  if lower:find("%f[%a]elemental%f[%A]") then
    return "Elemental"
  end
  return ""
end

local function normalize_current_form(value)
  if type(value) ~= "string" then return "" end
  local lower = trim(value):lower()
  if lower == "dragon" then return "Dragon" end
  if lower == "elemental" then return "Elemental" end
  return ""
end

local function normalize_elemental_type(value)
  if value == nil then return nil end
  if type(value) ~= "string" then return "" end
  local lower = trim(value):lower()
  if lower == "" or lower == "none" or lower == "clear" or lower == "reset" then
    return ""
  end
  local map = {
    air = "Air",
    earth = "Earth",
    fire = "Fire",
    water = "Water",
  }
  return map[lower] or ""
end

local function normalize_race(value)
  if value == nil then return nil end
  if type(value) ~= "string" then return "" end

  local lower = trim(value):lower()
  if lower == "" then return "" end
  if lower:match("^%d+$") then return "" end

  lower = lower:gsub("[%.,;:!]+$", "")
  lower = lower:gsub("^non%-binary%s+", "")
  lower = lower:gsub("^male%s+", "")
  lower = lower:gsub("^female%s+", "")
  lower = lower:gsub("^chaos%s+lord%s+", "")
  lower = lower:gsub("^chaos%s+lady%s+", "")
  lower = lower:gsub("^chaos%s+noble%s+", "")

  local resembling = lower:match("resembling%s+an?%s+([%a'%-]+)")
  if resembling then
    return canonical_base_race(resembling)
  end

  for race_key, race_name in pairs(base_races) do
    local pattern = race_key:gsub("([^%w])", "%%%1")
    if lower:find(pattern .. "$") then
      return race_name
    end
  end

  if detect_current_form(lower) ~= "" then
    return ""
  end

  return canonical_base_race(lower)
end

local function normalize_class(value)
  if value == nil then return nil end
  if type(value) ~= "string" then return "" end
  local trimmed = trim(value)
  if trimmed == "" then return "" end
  return titlecase_words(trimmed)
end

local function db_conn()
  if not db or not db.__conn then return nil end
  return db.__conn[agnosticdb.db.name:lower()]
end

local function table_exists(name)
  local conn = db_conn()
  if not conn then return false end
  local cursor = conn:execute(string.format(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='%s'",
    tostring(name)
  ))
  if not cursor then return false end
  local row = cursor:fetch({}, "a")
  if cursor.close then cursor:close() end
  return row and row.name == name
end

local function column_exists(table_name, column)
  local conn = db_conn()
  if not conn then return false end
  local cursor = conn:execute(string.format("PRAGMA table_info(%s)", tostring(table_name)))
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

local function add_column_if_missing(table_name, row, column, sql)
  if row and row[column] ~= nil then return end
  if column_exists(table_name, column) then return end
  local conn = db_conn()
  if not conn then return end
  conn:execute(sql)
  if conn.commit then conn:commit() end
end

local function ensure_class_specs_table()
  if table_exists("class_specs") then return end
  local conn = db_conn()
  if not conn then return end
  conn:execute([[
    CREATE TABLE IF NOT EXISTS class_specs (
      name TEXT NOT NULL,
      class TEXT NOT NULL,
      specialization TEXT NULL DEFAULT "",
      last_updated INTEGER NULL DEFAULT 0,
      source TEXT NULL DEFAULT "",
      UNIQUE(name, class) ON CONFLICT REPLACE
    )
  ]])
  if conn.commit then conn:commit() end
end

local function required_people_columns()
  return {
    "name",
    "class",
    "city",
    "house",
    "race",
    "army_rank",
    "current_form",
    "elemental_type",
    "enemy_city",
    "enemy_house",
    "title",
    "notes",
    "iff",
    "city_rank",
    "xp_rank",
    "level",
    "immortal",
    "last_checked",
    "last_updated",
    "source"
  }
end

local function required_class_specs_columns()
  return {
    "name",
    "class",
    "specialization",
    "last_updated",
    "source",
  }
end

function agnosticdb.db.safe_fetch(tbl, clause)
  if agnosticdb.db.disabled then return nil end
  if not db or not tbl then return nil end
  return safe_call(db.fetch, db, tbl, clause)
end

function agnosticdb.db.ensure()
  if agnosticdb.db.disabled then return false end
  if agnosticdb.db.people and agnosticdb.db.class_specs ~= nil then return true end
  if agnosticdb.db.init then
    agnosticdb.db.init()
  end
  return agnosticdb.db.people ~= nil and agnosticdb.db.class_specs ~= nil and not agnosticdb.db.disabled
end

local function people_field_defaults()
  return {
    class = "",
    city = "",
    house = "",
    race = "",
    army_rank = -1,
    current_form = "",
    elemental_type = "",
    enemy_city = "",
    enemy_house = "",
    title = "",
    notes = "",
    iff = "auto",
    city_rank = -1,
    xp_rank = -1,
    level = -1,
    immortal = 0,
    source = "",
  }
end

local function numeric_people_fields()
  return {
    army_rank = true,
    city_rank = true,
    xp_rank = true,
    level = true,
    immortal = true,
  }
end

local function sql_quote(value)
  if value == nil then return "''" end
  return "'" .. tostring(value):gsub("'", "''") .. "'"
end

local function upsert_class_spec_record(record)
  local conn = db_conn()
  if not conn or type(record) ~= "table" then return nil end
  local sql = string.format(
    "INSERT OR REPLACE INTO class_specs (name, class, specialization, last_updated, source) VALUES (%s, %s, %s, %d, %s)",
    sql_quote(record.name),
    sql_quote(record.class),
    sql_quote(record.specialization or ""),
    tonumber(record.last_updated or 0) or 0,
    sql_quote(record.source or "")
  )
  conn:execute(sql)
  if conn.commit then conn:commit() end
  return true
end

local function sql_number(value, default)
  local num = tonumber(value)
  if num == nil then
    num = default or 0
  end
  return tostring(num)
end

local function upsert_people_record(record)
  local conn = db_conn()
  if not conn or type(record) ~= "table" then return nil end
  local sql = string.format([[
    INSERT OR REPLACE INTO people (
      name, class, city, house, race, army_rank,
      current_form, elemental_type, enemy_city, enemy_house,
      title, notes, iff, city_rank, xp_rank, level, immortal,
      last_checked, last_updated, source
    ) VALUES (
      %s, %s, %s, %s, %s, %s,
      %s, %s, %s, %s,
      %s, %s, %s, %s, %s, %s, %s,
      %s, %s, %s
    )
  ]],
    sql_quote(record.name),
    sql_quote(record.class or ""),
    sql_quote(record.city or ""),
    sql_quote(record.house or ""),
    sql_quote(record.race or ""),
    sql_number(record.army_rank, -1),
    sql_quote(record.current_form or ""),
    sql_quote(record.elemental_type or ""),
    sql_quote(record.enemy_city or ""),
    sql_quote(record.enemy_house or ""),
    sql_quote(record.title or ""),
    sql_quote(record.notes or ""),
    sql_quote(record.iff or "auto"),
    sql_number(record.city_rank, -1),
    sql_number(record.xp_rank, -1),
    sql_number(record.level, -1),
    sql_number(record.immortal, 0),
    sql_number(record.last_checked, 0),
    sql_number(record.last_updated, 0),
    sql_quote(record.source or "")
  )
  conn:execute(sql)
  if conn.commit then conn:commit() end
  return true
end

local function delete_person_row_by_name(name)
  if type(name) ~= "string" or name == "" then return end
  local conn = db_conn()
  if not conn then return end
  conn:execute(string.format("DELETE FROM people WHERE name = %s", sql_quote(name)))
  conn:execute(string.format("DELETE FROM class_specs WHERE name = %s", sql_quote(name)))
  if conn.commit then conn:commit() end
end

local function fetch_sql_rows(sql)
  local conn = db_conn()
  if not conn then return {} end
  local cursor = conn:execute(sql)
  if not cursor then return {} end
  local rows = {}
  local row = cursor:fetch({}, "a")
  while row do
    rows[#rows + 1] = row
    row = cursor:fetch({}, "a")
  end
  if cursor.close then cursor:close() end
  return rows
end

local function get_class_spec_row(name, class)
  if not agnosticdb.db.ensure() then return nil end
  local normalized = normalize_name(name)
  local normalized_class = normalize_class(class)
  if not normalized or not normalized_class or normalized_class == "" then return nil end
  local rows = fetch_sql_rows(string.format(
    "SELECT name, class, specialization, last_updated, source FROM class_specs WHERE name = %s",
    sql_quote(normalized)
  ))
  for _, row in ipairs(rows) do
    if row.class == normalized_class then
      return row
    end
  end
  return nil
end

local function migrate_legacy_rows()
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  if not rows then return end

  for _, row in ipairs(rows) do
    local name = row.name
    if not is_valid_person_name(name) then
      delete_person_row_by_name(name)
    else
      local normalized_name = normalize_name(name)
      local normalized_class = normalize_class(row.class) or ""
      local normalized_race = normalize_race(row.race)
      local current_form = normalize_current_form(row.current_form)
      local elemental_type = normalize_elemental_type(row.elemental_type)

      if current_form == "" then
        current_form = detect_current_form(row.race)
      end
      if current_form == "" and tonumber(row.dragon or 0) == 1 then
        current_form = "Dragon"
      end
      if current_form == "" and type(row.elemental_lord_type) == "string" and row.elemental_lord_type ~= "" then
        current_form = "Elemental"
      end

      if elemental_type == nil or elemental_type == "" then
        elemental_type = normalize_elemental_type(row.elemental_lord_type) or ""
      end

      if normalized_class:find(" Dragon$") or normalized_class == "Dragon" or normalized_class == "Elemental" then
        normalized_class = ""
      end

      if type(row.specialization) == "string" and row.specialization ~= "" and normalized_class ~= "" then
        local spec_record = {
          name = normalized_name,
          class = normalized_class,
          specialization = row.specialization,
          last_updated = tonumber(row.last_updated or 0) or os.time(),
          source = row.source or "",
        }
        upsert_class_spec_record(spec_record)
      end

      local updated = {
        name = normalized_name,
        class = normalized_class,
        city = row.city or "",
        house = row.house or "",
        race = normalized_race,
        army_rank = tonumber(row.army_rank or -1) or -1,
        current_form = current_form,
        elemental_type = elemental_type or "",
        enemy_city = row.enemy_city or "",
        enemy_house = row.enemy_house or "",
        title = row.title or "",
        notes = row.notes or "",
        iff = row.iff or "auto",
        city_rank = tonumber(row.city_rank or -1) or -1,
        xp_rank = tonumber(row.xp_rank or -1) or -1,
        level = tonumber(row.level or -1) or -1,
        immortal = tonumber(row.immortal or 0) or 0,
        last_checked = tonumber(row.last_checked or 0) or 0,
        last_updated = tonumber(row.last_updated or 0) or 0,
        source = row.source or "",
      }
      upsert_people_record(updated)
    end
  end
end

local function rebuild_people_table_without_legacy_columns()
  local conn = db_conn()
  if not conn then return end

  local legacy_present = column_exists("people", "specialization")
    or column_exists("people", "elemental_lord_type")
    or column_exists("people", "dragon")
  if not legacy_present then return end

  local rows = fetch_sql_rows([[
    SELECT
      name, class, city, house, race, army_rank,
      current_form, elemental_type, enemy_city, enemy_house,
      title, notes, iff, city_rank, xp_rank, level, immortal,
      last_checked, last_updated, source
    FROM people
  ]])

  conn:execute("DROP TABLE IF EXISTS people")
  conn:execute([[
    CREATE TABLE people (
      name TEXT NULL DEFAULT "",
      class TEXT NULL DEFAULT "",
      city TEXT NULL DEFAULT "",
      house TEXT NULL DEFAULT "",
      race TEXT NULL DEFAULT "",
      army_rank INTEGER NULL DEFAULT -1,
      current_form TEXT NULL DEFAULT "",
      elemental_type TEXT NULL DEFAULT "",
      enemy_city TEXT NULL DEFAULT "",
      enemy_house TEXT NULL DEFAULT "",
      title TEXT NULL DEFAULT "",
      notes TEXT NULL DEFAULT "",
      iff TEXT NULL DEFAULT "auto",
      city_rank INTEGER NULL DEFAULT -1,
      xp_rank INTEGER NULL DEFAULT -1,
      level INTEGER NULL DEFAULT -1,
      immortal INTEGER NULL DEFAULT 0,
      last_checked INTEGER NULL DEFAULT 0,
      last_updated INTEGER NULL DEFAULT 0,
      source TEXT NULL DEFAULT "",
      UNIQUE(name) ON CONFLICT REPLACE
    )
  ]])
  if conn.commit then conn:commit() end

  for _, row in ipairs(rows) do
    upsert_people_record(row)
  end
end

function agnosticdb.db.check()
  agnosticdb.db.disabled = false
  agnosticdb.db.error_reported = false

  if not db then
    return false, { "Mudlet DB API unavailable." }
  end

  if not agnosticdb.db.ensure() then
    return false, { "Failed to initialize agnosticdb database." }
  end

  if not table_exists("people") then
    return false, { "Missing people table.", "Run adb dbreset or delete the DB file." }
  end
  if not table_exists("class_specs") then
    return false, { "Missing class_specs table.", "Run adb dbreset or delete the DB file." }
  end

  local missing = {}
  for _, column in ipairs(required_people_columns()) do
    if not column_exists("people", column) then
      missing[#missing + 1] = "people." .. column
    end
  end
  for _, column in ipairs(required_class_specs_columns()) do
    if not column_exists("class_specs", column) then
      missing[#missing + 1] = "class_specs." .. column
    end
  end

  if #missing > 0 then
    return false, { "Missing columns: " .. table.concat(missing, ", "), "Run adb dbreset to rebuild schema." }
  end

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  if agnosticdb.db.disabled then
    return false, { "Database query failed. Run adb dbreset or delete the DB file." }
  end

  local specs = fetch_sql_rows("SELECT name, class FROM class_specs")
  return true, {
    "Schema OK.",
    string.format("People rows: %d", rows and #rows or 0),
    string.format("Class spec rows: %d", specs and #specs or 0),
  }
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

  local ok, err = pcall(conn.execute, conn, "DROP TABLE IF EXISTS class_specs")
  if not ok then
    return false, err
  end
  ok, err = pcall(conn.execute, conn, "DROP TABLE IF EXISTS people")
  if not ok then
    return false, err
  end
  if conn.commit then conn:commit() end

  agnosticdb.db.handle = nil
  agnosticdb.db.people = nil
  agnosticdb.db.class_specs = nil
  agnosticdb.db.init()
  if not agnosticdb.db.people or not agnosticdb.db.class_specs then
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
      race = "",
      army_rank = -1,
      current_form = "",
      elemental_type = "",
      enemy_city = "",
      enemy_house = "",
      title = "",
      notes = "",
      iff = "auto",
      city_rank = -1,
      xp_rank = -1,
      level = -1,
      immortal = 0,
      last_checked = 0,
      last_updated = 0,
      source = "",

      _unique = { "name" },
      _violations = "REPLACE"
    }
  }

  agnosticdb.db.handle = safe_call(db.create, db, "agnosticdb", agnosticdb.db.schema)
  if not agnosticdb.db.handle then return end

  ensure_class_specs_table()
  agnosticdb.db.people = agnosticdb.db.handle.people
  agnosticdb.db.class_specs = true

  local people_rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  local people_sample = people_rows and people_rows[1] or nil
  add_column_if_missing("people", people_sample, "notes", [[ALTER TABLE people ADD COLUMN "notes" TEXT NULL DEFAULT ""]])
  add_column_if_missing("people", people_sample, "iff", [[ALTER TABLE people ADD COLUMN "iff" TEXT NULL DEFAULT "auto"]])
  add_column_if_missing("people", people_sample, "race", [[ALTER TABLE people ADD COLUMN "race" TEXT NULL DEFAULT ""]])
  add_column_if_missing("people", people_sample, "army_rank", [[ALTER TABLE people ADD COLUMN "army_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing("people", people_sample, "current_form", [[ALTER TABLE people ADD COLUMN "current_form" TEXT NULL DEFAULT ""]])
  add_column_if_missing("people", people_sample, "elemental_type", [[ALTER TABLE people ADD COLUMN "elemental_type" TEXT NULL DEFAULT ""]])
  add_column_if_missing("people", people_sample, "enemy_city", [[ALTER TABLE people ADD COLUMN "enemy_city" TEXT NULL DEFAULT ""]])
  add_column_if_missing("people", people_sample, "enemy_house", [[ALTER TABLE people ADD COLUMN "enemy_house" TEXT NULL DEFAULT ""]])
  add_column_if_missing("people", people_sample, "city_rank", [[ALTER TABLE people ADD COLUMN "city_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing("people", people_sample, "xp_rank", [[ALTER TABLE people ADD COLUMN "xp_rank" INTEGER NULL DEFAULT -1]])
  add_column_if_missing("people", people_sample, "level", [[ALTER TABLE people ADD COLUMN "level" INTEGER NULL DEFAULT -1]])
  add_column_if_missing("people", people_sample, "immortal", [[ALTER TABLE people ADD COLUMN "immortal" INTEGER NULL DEFAULT 0]])
  add_column_if_missing("people", people_sample, "last_checked", [[ALTER TABLE people ADD COLUMN "last_checked" INTEGER NULL DEFAULT 0]])
  add_column_if_missing("people", people_sample, "last_updated", [[ALTER TABLE people ADD COLUMN "last_updated" INTEGER NULL DEFAULT 0]])
  add_column_if_missing("people", people_sample, "source", [[ALTER TABLE people ADD COLUMN "source" TEXT NULL DEFAULT ""]])

  add_column_if_missing("class_specs", nil, "specialization", [[ALTER TABLE class_specs ADD COLUMN "specialization" TEXT NULL DEFAULT ""]])
  add_column_if_missing("class_specs", nil, "last_updated", [[ALTER TABLE class_specs ADD COLUMN "last_updated" INTEGER NULL DEFAULT 0]])
  add_column_if_missing("class_specs", nil, "source", [[ALTER TABLE class_specs ADD COLUMN "source" TEXT NULL DEFAULT ""]])

  migrate_legacy_rows()
  rebuild_people_table_without_legacy_columns()
end

function agnosticdb.db.get_person(name)
  if not agnosticdb.db.ensure() then return nil end
  local normalized = normalize_name(name)
  if not normalized then return nil end
  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people, db:eq(agnosticdb.db.people.name, normalized))
  return rows and rows[1] or nil
end

function agnosticdb.db.get_class_specs(name)
  if not agnosticdb.db.ensure() then return {} end
  local normalized = normalize_name(name)
  if not normalized then return {} end
  local rows = fetch_sql_rows(string.format(
    "SELECT name, class, specialization, last_updated, source FROM class_specs WHERE name = %s",
    sql_quote(normalized)
  ))
  table.sort(rows, function(a, b)
    local left = tostring(a.class or "")
    local right = tostring(b.class or "")
    return left:lower() < right:lower()
  end)
  return rows
end

function agnosticdb.db.get_class_spec(name, class)
  local row = get_class_spec_row(name, class)
  if not row then return nil end
  if row.specialization == "" then return nil end
  return row.specialization
end

function agnosticdb.db.set_class_spec(name, class, specialization, source, last_updated)
  if not agnosticdb.db.ensure() then return nil end
  local normalized_name = normalize_name(name)
  local normalized_class = normalize_class(class)
  if not normalized_name or not normalized_class or normalized_class == "" then return nil end

  local record = {
    name = normalized_name,
    class = normalized_class,
    specialization = type(specialization) == "string" and trim(specialization) or "",
    last_updated = tonumber(last_updated or os.time()) or os.time(),
    source = type(source) == "string" and source or "",
  }
  upsert_class_spec_record(record)
  return agnosticdb.db.get_class_spec(normalized_name, normalized_class)
end

function agnosticdb.db.clear_class_spec(name, class)
  if not agnosticdb.db.ensure() then return end
  local normalized_name = normalize_name(name)
  local normalized_class = normalize_class(class)
  if not normalized_name or not normalized_class or normalized_class == "" then return end
  local conn = db_conn()
  if not conn then return end
  local safe_name = normalized_name:gsub("'", "''")
  local safe_class = normalized_class:gsub("'", "''")
  conn:execute(string.format(
    "DELETE FROM class_specs WHERE name = '%s' AND class = '%s'",
    safe_name,
    safe_class
  ))
  if conn.commit then conn:commit() end
end

function agnosticdb.db.get_current_specialization(name_or_person)
  local person = name_or_person
  if type(name_or_person) == "string" then
    person = agnosticdb.db.get_person(name_or_person)
  end
  if type(person) ~= "table" then return nil end
  if type(person.class) ~= "string" or person.class == "" then return nil end
  return agnosticdb.db.get_class_spec(person.name, person.class)
end

function agnosticdb.db.upsert_person(fields, opts)
  if not agnosticdb.db.ensure() or type(fields) ~= "table" then return end
  opts = opts or {}

  local normalized = normalize_name(fields.name)
  if not normalized then return end

  local caller_supplied_last_updated = fields.last_updated ~= nil
  local caller_supplied_last_checked = fields.last_checked ~= nil
  local caller_supplied_race = fields.race ~= nil
  local caller_supplied_current_form = fields.current_form ~= nil
  local caller_supplied_elemental_type = fields.elemental_type ~= nil

  local existing = agnosticdb.db.get_person(normalized)
  local record = {}
  for k, v in pairs(fields) do
    if k:sub(1, 1) ~= "_" then
      record[k] = v
    end
  end
  record.name = normalized

  if existing then
    for k, v in pairs(existing) do
      if record[k] == nil then
        record[k] = v
      end
    end
  end

  record.class = normalize_class(record.class) or ""
  record.city = type(record.city) == "string" and record.city or ""
  record.house = type(record.house) == "string" and record.house or ""
  record.title = type(record.title) == "string" and record.title or ""
  record.notes = type(record.notes) == "string" and record.notes or ""
  record.iff = type(record.iff) == "string" and record.iff or "auto"
  record.enemy_city = type(record.enemy_city) == "string" and record.enemy_city or ""
  record.enemy_house = type(record.enemy_house) == "string" and record.enemy_house or ""
  record.source = type(record.source) == "string" and record.source or ""

  local derived_form_from_race = caller_supplied_race and detect_current_form(fields.race) or ""
  if caller_supplied_race then
    local normalized_race = normalize_race(fields.race)
    if normalized_race ~= "" or fields.race == "" then
      record.race = normalized_race
    elseif derived_form_from_race == "" then
      record.race = ""
    end
  else
    record.race = type(record.race) == "string" and record.race or ""
  end

  if caller_supplied_current_form then
    record.current_form = normalize_current_form(fields.current_form)
  elseif derived_form_from_race ~= "" then
    record.current_form = derived_form_from_race
  else
    record.current_form = normalize_current_form(record.current_form)
  end

  if caller_supplied_elemental_type then
    record.elemental_type = normalize_elemental_type(fields.elemental_type) or ""
  else
    record.elemental_type = normalize_elemental_type(record.elemental_type) or ""
  end

  local function normalize_numeric(value, default)
    local num = tonumber(value)
    if num == nil then return default end
    return num
  end

  record.army_rank = normalize_numeric(record.army_rank, -1)
  record.city_rank = normalize_numeric(record.city_rank, -1)
  record.xp_rank = normalize_numeric(record.xp_rank, -1)
  record.level = normalize_numeric(record.level, -1)
  record.immortal = normalize_numeric(record.immortal, 0)
  record.last_checked = normalize_numeric(record.last_checked, 0)
  record.last_updated = normalize_numeric(record.last_updated, 0)

  local field_defaults = people_field_defaults()
  local numeric_fields = numeric_people_fields()

  local function normalize_string(value, default)
    if value == nil then return default end
    return tostring(value)
  end

  local function record_changed()
    if not existing then return true end
    for field, default in pairs(field_defaults) do
      local new_value = record[field]
      local old_value = existing[field]
      if numeric_fields[field] then
        new_value = normalize_numeric(new_value, default)
        old_value = normalize_numeric(old_value, default)
      else
        new_value = normalize_string(new_value, default)
        old_value = normalize_string(old_value, default)
      end
      if new_value ~= old_value then
        return true
      end
    end
    return false
  end

  local changed = record_changed()
  if not caller_supplied_last_updated then
    if changed then
      record.last_updated = os.time()
    else
      record.last_updated = existing and existing.last_updated or 0
    end
  end

  if not caller_supplied_last_checked and (record.last_checked == 0 or record.last_checked == nil) then
    record.last_checked = os.time()
  end

  upsert_people_record(record)

  if type(fields.class_spec) == "table" then
    agnosticdb.db.set_class_spec(
      normalized,
      fields.class_spec.class or record.class,
      fields.class_spec.specialization,
      fields.class_spec.source or record.source,
      fields.class_spec.last_updated or record.last_updated
    )
  end

  if type(fields.specialization) == "string" and fields.specialization ~= "" and record.class ~= "" then
    agnosticdb.db.set_class_spec(normalized, record.class, fields.specialization, record.source, record.last_updated)
  end

  local updated = agnosticdb.db.get_person(normalized)
  if updated and not opts.skip_highlight and agnosticdb.highlights and agnosticdb.highlights.update then
    agnosticdb.highlights.update(updated)
  end
  return changed, updated
end

agnosticdb.db.normalize_name = normalize_name
agnosticdb.db.normalize_class = normalize_class
agnosticdb.db.normalize_race = normalize_race
agnosticdb.db.normalize_current_form = normalize_current_form
agnosticdb.db.normalize_elemental_type = normalize_elemental_type
agnosticdb.db.detect_current_form = detect_current_form

function agnosticdb.db.delete_person(name)
  if not agnosticdb.db.ensure() then return end
  local normalized = normalize_name(name)
  if not normalized then return end
  delete_person_row_by_name(normalized)
  if agnosticdb.highlights and agnosticdb.highlights.remove then
    agnosticdb.highlights.remove(normalized)
  end
end

local function get_person_record(name)
  if not agnosticdb.db or not agnosticdb.db.get_person then return nil end
  return agnosticdb.db.get_person(name)
end

local function get_field(name, key)
  local person = get_person_record(name)
  if not person then return nil end
  local value = person[key]
  if value == "" then return nil end
  return value
end

function agnosticdb.getPerson(name)
  return get_person_record(name)
end

function agnosticdb.getClass(name)
  return get_field(name, "class")
end

function agnosticdb.getSpecialization(name)
  return agnosticdb.db.get_current_specialization(name)
end

function agnosticdb.getCity(name)
  return get_field(name, "city")
end

function agnosticdb.getHouse(name)
  return get_field(name, "house")
end

function agnosticdb.getRace(name)
  return get_field(name, "race")
end

function agnosticdb.getCurrentForm(name)
  return get_field(name, "current_form")
end

function agnosticdb.getCityColor(name)
  local city = agnosticdb.getCity(name)
  if not city or city == "" then return nil end
  local cfg = agnosticdb.conf and agnosticdb.conf.highlight and agnosticdb.conf.highlight.cities or nil
  if not cfg then return nil end
  local key = city:lower()
  if key == "(none)" or key == "none" then
    key = "rogue"
  end
  local entry = cfg[key]
  if entry and entry.color and entry.color ~= "" then
    return entry.color
  end
  return nil
end

function agnosticdb.getElementalType(name)
  return get_field(name, "elemental_type")
end

function agnosticdb.getElementalLordType(name)
  return agnosticdb.getElementalType(name)
end

function agnosticdb.getLevel(name)
  local value = get_field(name, "level")
  if value == nil or value < 0 then return nil end
  return value
end

function agnosticdb.getTitle(name)
  return get_field(name, "title")
end

function agnosticdb.getXpRank(name)
  local value = get_field(name, "xp_rank")
  if value == nil or value < 0 then return nil end
  return value
end

function agnosticdb.getCityRank(name)
  local value = get_field(name, "city_rank")
  if value == nil or value < 0 then return nil end
  return value
end

function agnosticdb.getArmyRank(name)
  local value = get_field(name, "army_rank")
  if value == nil or value < 0 then return nil end
  return value
end

function agnosticdb.getIff(name)
  return get_field(name, "iff")
end

function agnosticdb.getEnemyCity(name)
  return get_field(name, "enemy_city")
end

function agnosticdb.getEnemyHouse(name)
  return get_field(name, "enemy_house")
end

function agnosticdb.getNotes(name)
  return get_field(name, "notes")
end

function agnosticdb.getLastChecked(name)
  local value = get_field(name, "last_checked")
  if value == nil or value <= 0 then return nil end
  return value
end

function agnosticdb.getSource(name)
  return get_field(name, "source")
end
