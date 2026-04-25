agnosticdb = agnosticdb or {}

agnosticdb.transfer = agnosticdb.transfer or {}

local function is_abs(path)
  if not path or path == "" then return false end
  if path:match("^/") then return true end
  if path:match("^[A-Za-z]:[\\/]")
  then return true end
  return false
end

local function base_dir()
  return getMudletHomeDir() .. "/agnosticdb"
end

local function export_dir()
  return base_dir() .. "/exports"
end

local function ensure_dir(dir)
  if not dir or dir == "" then return end
  if not lfs then return end
  if not lfs.attributes(dir) then
    lfs.mkdir(dir)
  end
end

local function normalize_path(path, dir)
  if not path or path == "" then return nil end
  local normalized = path
  if not normalized:find("%.json$") then
    normalized = normalized .. ".json"
  end
  if is_abs(normalized) then
    return normalized
  end
  return (dir or base_dir()) .. "/" .. normalized
end

local function can_json()
  return yajl and type(yajl.to_string) == "function" and type(yajl.to_value) == "function"
end

local function set_if(record, key, value, default)
  if value == nil then return end
  if type(value) == "string" and value == "" then return end
  if default ~= nil and value == default then return end
  record[key] = value
end

local function serialize_person(row)
  if not row or type(row.name) ~= "string" or row.name == "" then return nil end
  local record = { name = row.name }
  local class_specs = agnosticdb.db and agnosticdb.db.get_class_specs and agnosticdb.db.get_class_specs(row.name) or {}

  set_if(record, "class", row.class, "")
  set_if(record, "city", row.city, "")
  set_if(record, "house", row.house, "")
  set_if(record, "race", row.race, "")
  set_if(record, "current_form", row.current_form, "")
  set_if(record, "elemental_type", row.elemental_type, "")
  set_if(record, "title", row.title, "")
  set_if(record, "notes", row.notes, "")
  set_if(record, "iff", row.iff, "auto")
  set_if(record, "enemy_city", row.enemy_city, "")
  set_if(record, "enemy_house", row.enemy_house, "")
  set_if(record, "city_rank", row.city_rank, -1)
  set_if(record, "xp_rank", row.xp_rank, -1)
  set_if(record, "army_rank", row.army_rank, -1)
  set_if(record, "level", row.level, -1)
  set_if(record, "immortal", row.immortal, 0)
  set_if(record, "last_checked", row.last_checked, 0)
  set_if(record, "last_updated", row.last_updated, 0)
  set_if(record, "source", row.source, "")
  if class_specs and #class_specs > 0 then
    record.class_specs = {}
    for _, spec in ipairs(class_specs) do
      record.class_specs[#record.class_specs + 1] = {
        class = spec.class,
        specialization = spec.specialization,
        last_updated = tonumber(spec.last_updated or 0) or 0,
        source = spec.source or "",
      }
    end
  end

  return record
end

function agnosticdb.transfer.exportData(path)
  if not can_json() then
    return nil, "json_unavailable"
  end
  if not agnosticdb.db or not agnosticdb.db.ensure or not agnosticdb.db.ensure() then
    return nil, "db_unavailable"
  end

  local rows = agnosticdb.db.safe_fetch(agnosticdb.db.people)
  if not rows then
    return nil, "db_error"
  end

  local payload = {
    version = 2,
    exported_at = os.time(),
    people = {}
  }

  for _, row in ipairs(rows) do
    local record = serialize_person(row)
    if record then
      payload.people[#payload.people + 1] = record
    end
  end

  local output_path = path
  if not output_path or output_path == "" then
    ensure_dir(export_dir())
    local filename = string.format("agnosticdb-export-%s.json", os.date("%Y%m%d-%H%M%S"))
    output_path = export_dir() .. "/" .. filename
  else
    output_path = normalize_path(output_path, base_dir())
  end

  local ok, encoded = pcall(yajl.to_string, payload)
  if not ok then
    return nil, "encode_failed"
  end

  local file, err = io.open(output_path, "w")
  if not file then
    return nil, "io_error:" .. tostring(err)
  end
  file:write(encoded)
  file:close()

  return { path = output_path, count = #payload.people }
end

function agnosticdb.transfer.importData(path)
  if not can_json() then
    return nil, "json_unavailable"
  end
  if not path or path == "" then
    return nil, "path_required"
  end
  if not agnosticdb.db or not agnosticdb.db.ensure or not agnosticdb.db.ensure() then
    return nil, "db_unavailable"
  end

  local input_path = normalize_path(path, base_dir())
  local file, err = io.open(input_path, "r")
  if not file then
    return nil, "io_error:" .. tostring(err)
  end
  local content = file:read("*a")
  file:close()

  local ok, data = pcall(yajl.to_value, content)
  if not ok or type(data) ~= "table" then
    return nil, "decode_failed"
  end

  local records = data.people or data
  if type(records) ~= "table" then
    return nil, "invalid_format"
  end

  local stats = { imported = 0, skipped = 0, path = input_path }

  local function import_record(record, name_override)
    if type(record) ~= "table" then
      stats.skipped = stats.skipped + 1
      return
    end
    local name = record.name or name_override
    if type(name) ~= "string" or name == "" then
      stats.skipped = stats.skipped + 1
      return
    end
    local copy = {}
    for key, value in pairs(record) do
      copy[key] = value
    end
    copy.name = name
    if copy.elemental_type == nil and copy.elemental_lord_type ~= nil then
      copy.elemental_type = copy.elemental_lord_type
    end
    local legacy_class = type(copy.class) == "string" and copy.class:lower() or ""
    if copy.current_form == nil then
      local detected = type(copy.race) == "string" and agnosticdb.db.detect_current_form and agnosticdb.db.detect_current_form(copy.race) or ""
      if detected ~= "" then
        copy.current_form = detected
      elseif tonumber(copy.dragon or 0) == 1 then
        copy.current_form = "Dragon"
      elseif legacy_class == "dragon" or legacy_class:find(" dragon$") then
        copy.current_form = "Dragon"
      elseif legacy_class == "elemental" then
        copy.current_form = "Elemental"
      elseif copy.elemental_lord_type ~= nil and tostring(copy.elemental_lord_type) ~= "" then
        copy.current_form = "Elemental"
      end
    end
    if legacy_class == "dragon" or legacy_class == "elemental" or legacy_class:find(" dragon$") then
      copy.class = ""
    end

    local class_specs = copy.class_specs
    copy.class_specs = nil
    agnosticdb.db.upsert_person(copy)
    if type(class_specs) == "table" then
      for _, spec in ipairs(class_specs) do
        if type(spec) == "table" then
          agnosticdb.db.set_class_spec(
            name,
            spec.class,
            spec.specialization or "",
            spec.source or copy.source or "import",
            spec.last_updated or copy.last_updated or os.time()
          )
        end
      end
    end
    stats.imported = stats.imported + 1
  end

  if records[1] ~= nil then
    for _, record in ipairs(records) do
      import_record(record)
    end
  else
    for name, record in pairs(records) do
      import_record(record, name)
    end
  end

  if agnosticdb.highlights and agnosticdb.highlights.reload then
    agnosticdb.highlights.reload()
  end

  return stats
end
