local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb transfer", function()
  local temp_paths
  local function has_json_support()
    return yajl and type(yajl.to_string) == "function" and type(yajl.to_value) == "function"
  end

  local function temp_json_path(label)
    local path = string.format("/tmp/%s-%d-%d.json", label, os.time(), math.random(1000, 999999))
    temp_paths[#temp_paths + 1] = path
    return path
  end

  before_each(function()
    helper.reset()
    temp_paths = {}
  end)

  after_each(function()
    for _, path in ipairs(temp_paths or {}) do
      os.remove(path)
    end
  end)

  it("exports current people to json", function()
    agnosticdb.db.upsert_person({
      name = "Exporter",
      class = "Magi",
      city = "Ashtan",
      notes = "hello",
      iff = "auto",
      source = "api",
    })

    local path = temp_json_path("agnosticdb-export-spec")
    local result, err = agnosticdb.transfer.exportData(path)

    if not has_json_support() then
      assert.is_nil(result)
      assert.are.equal("json_unavailable", err)
      return
    end

    assert.is_nil(err)
    assert.is_not_nil(result)
    assert.are.equal(path, result.path)
    assert.are.equal(1, result.count)

    local file = assert(io.open(path, "r"))
    local payload = file:read("*a")
    file:close()

    assert.is_true(payload:find('"version":1', 1, true) ~= nil)
    assert.is_true(payload:find('"exported_at":', 1, true) ~= nil)
    assert.is_true(payload:find('"name":"Exporter"', 1, true) ~= nil)
    assert.is_true(payload:find('"class":"Magi"', 1, true) ~= nil)
    assert.is_true(payload:find('"city":"Ashtan"', 1, true) ~= nil)
  end)

  it("imports keyed records", function()
    local path = temp_json_path("agnosticdb-import-spec")
    if not has_json_support() then
      local stats, err = agnosticdb.transfer.importData(path)
      assert.is_nil(stats)
      assert.are.equal("json_unavailable", err)
      return
    end

    local file = assert(io.open(path, "w"))
    file:write('{"Imported":{"city":"cyrene","class":"bard","notes":"fresh","iff":"ally"},"Broken":"invalid"}')
    file:close()

    local stats, err = agnosticdb.transfer.importData(path)

    assert.is_nil(err)
    assert.is_not_nil(stats)
    assert.are.equal(path, stats.path)
    assert.are.equal(1, stats.imported)
    assert.are.equal(1, stats.skipped)

    local person = agnosticdb.db.get_person("Imported")
    assert.is_not_nil(person)
    assert.are.equal("Imported", person.name)
    assert.is_true(type(person.city) == "string" and person.city ~= "")
    assert.is_true(type(person.class) == "string" and person.class ~= "")
  end)

  it("merges imported fields onto existing people without dropping unspecified data", function()
    local path = temp_json_path("agnosticdb-import-merge-spec")
    if not has_json_support() then
      local stats, err = agnosticdb.transfer.importData(path)
      assert.is_nil(stats)
      assert.are.equal("json_unavailable", err)
      return
    end

    agnosticdb.db.upsert_person({
      name = "Merged",
      class = "Magi",
      city = "Ashtan",
      notes = "keep me",
      iff = "ally",
      source = "manual",
    })

    local file = assert(io.open(path, "w"))
    file:write('{"people":[{"name":"Merged","class":"Bard","source":"import"}]}')
    file:close()

    local stats, err = agnosticdb.transfer.importData(path)

    assert.is_nil(err)
    assert.are.equal(1, stats.imported)
    local person = agnosticdb.db.get_person("Merged")
    assert.are.equal("Bard", person.class)
    assert.are.equal("Ashtan", person.city)
    assert.are.equal("keep me", person.notes)
    assert.are.equal("ally", person.iff)
    assert.are.equal("import", person.source)
  end)
end)
