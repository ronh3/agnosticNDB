agnosticdb = agnosticdb or {}

agnosticdb.class_tracking = agnosticdb.class_tracking or {}

local function normalize_name(name)
  if agnosticdb.db and agnosticdb.db.normalize_name then
    return agnosticdb.db.normalize_name(name)
  end
  if type(name) ~= "string" or name == "" then return nil end
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

local function normalize_class(class)
  if agnosticdb.db and agnosticdb.db.normalize_class then
    return agnosticdb.db.normalize_class(class)
  end
  if type(class) ~= "string" or class == "" then return nil end
  return class
end

local function update_person(fields)
  if not agnosticdb.db or not agnosticdb.db.upsert_person then return end
  agnosticdb.db.upsert_person(fields)
end

function agnosticdb.class_tracking.set_class(name, class)
  local normalized = normalize_name(name)
  local normalized_class = normalize_class(class)
  if not normalized or not normalized_class or normalized_class == "" then return end
  update_person({ name = normalized, class = normalized_class })
end

function agnosticdb.class_tracking.set_specialization(name, specialization, allowed_classes)
  local normalized = normalize_name(name)
  if not normalized or type(specialization) ~= "string" or specialization == "" then return end

  local person = agnosticdb.db and agnosticdb.db.get_person and agnosticdb.db.get_person(normalized) or nil
  if not person or type(person.class) ~= "string" or person.class == "" then
    return
  end

  if type(allowed_classes) == "table" and #allowed_classes > 0 then
    local allowed = {}
    for _, class in ipairs(allowed_classes) do
      local normalized_class = normalize_class(class)
      if normalized_class and normalized_class ~= "" then
        allowed[normalized_class] = true
      end
    end
    if not allowed[person.class] then
      return
    end
  end

  if agnosticdb.db and agnosticdb.db.set_class_spec then
    agnosticdb.db.set_class_spec(normalized, person.class, specialization, "class_tracking")
  end
end

function agnosticdb.class_tracking.set_class_spec(name, class, specialization)
  local normalized = normalize_name(name)
  local normalized_class = normalize_class(class)
  if not normalized or not normalized_class or normalized_class == "" then return end

  update_person({ name = normalized, class = normalized_class })
  if type(specialization) == "string" and specialization ~= "" and agnosticdb.db and agnosticdb.db.set_class_spec then
    agnosticdb.db.set_class_spec(normalized, normalized_class, specialization, "class_tracking")
  end
end

function agnosticdb.class_tracking.set_race(name, race, elemental_type)
  local normalized = normalize_name(name)
  if not normalized or type(race) ~= "string" or race == "" then return end

  local form = agnosticdb.db and agnosticdb.db.detect_current_form and agnosticdb.db.detect_current_form(race) or ""
  local record = { name = normalized }

  if form == "Dragon" then
    record.current_form = "Dragon"
  elseif form == "Elemental" then
    record.current_form = "Elemental"
    local normalized_type = agnosticdb.db and agnosticdb.db.normalize_elemental_type and agnosticdb.db.normalize_elemental_type(elemental_type) or elemental_type
    if normalized_type ~= nil then
      record.elemental_type = normalized_type
    end
  else
    record.race = race
    record.current_form = ""
  end

  update_person(record)
end
