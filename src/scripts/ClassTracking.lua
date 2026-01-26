agnosticdb = agnosticdb or {}

agnosticdb.class_tracking = agnosticdb.class_tracking or {}

local function normalize_name(name)
  if agnosticdb.db and agnosticdb.db.normalize_name then
    return agnosticdb.db.normalize_name(name)
  end
  if type(name) ~= "string" or name == "" then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function update_person(fields)
  if not agnosticdb.db or not agnosticdb.db.upsert_person then return end
  agnosticdb.db.upsert_person(fields)
end

function agnosticdb.class_tracking.set_class(name, class)
  local normalized = normalize_name(name)
  if not normalized or type(class) ~= "string" or class == "" then return end
  update_person({ name = normalized, class = class })
end

function agnosticdb.class_tracking.set_specialization(name, specialization)
  local normalized = normalize_name(name)
  if not normalized or type(specialization) ~= "string" or specialization == "" then return end
  update_person({ name = normalized, specialization = specialization })
end

function agnosticdb.class_tracking.set_class_spec(name, class, specialization)
  local normalized = normalize_name(name)
  if not normalized or type(class) ~= "string" or class == "" then return end
  local record = { name = normalized, class = class }
  if type(specialization) == "string" and specialization ~= "" then
    record.specialization = specialization
  end
  update_person(record)
end

function agnosticdb.class_tracking.set_race(name, race, elemental_type)
  local normalized = normalize_name(name)
  if not normalized or type(race) ~= "string" or race == "" then return end
  local record = { name = normalized, race = race }
  if race == "Dragon" then
    record.dragon = 1
  end
  if type(elemental_type) == "string" and elemental_type ~= "" then
    record.elemental_lord_type = elemental_type
  end
  update_person(record)
end
