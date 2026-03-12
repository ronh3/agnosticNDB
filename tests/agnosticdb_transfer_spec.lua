local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb transfer", function()
  local reload_stub
  local temp_paths

  local function temp_json_path(label)
    local path = string.format("%s/%s-%d-%d.json", getMudletHomeDir(), label, os.time(), math.random(1000, 999999))
    temp_paths[#temp_paths + 1] = path
    return path
  end

  before_each(function()
    helper.reset()
    temp_paths = {}
  end)

  after_each(function()
    if reload_stub then
      reload_stub:revert()
      reload_stub = nil
    end

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

    assert.is_nil(err)
    assert.is_not_nil(result)
    assert.are.equal(path, result.path)
    assert.are.equal(1, result.count)

    local file = assert(io.open(path, "r"))
    local payload = assert(yajl.to_value(file:read("*a")))
    file:close()

    assert.are.equal(1, payload.version)
    assert.are.equal(1, #payload.people)
    assert.are.equal("Exporter", payload.people[1].name)
    assert.are.equal("Magi", payload.people[1].class)
    assert.are.equal("Ashtan", payload.people[1].city)
    assert.are.equal("hello", payload.people[1].notes)
    assert.are.equal("api", payload.people[1].source)
    assert.is_nil(payload.people[1].iff)
  end)

  it("imports keyed records and refreshes highlights", function()
    local path = temp_json_path("agnosticdb-import-spec")
    local payload = {
      Imported = {
        city = "cyrene",
        class = "bard",
        notes = "fresh",
        iff = "ally",
      },
      Broken = "invalid",
    }

    local file = assert(io.open(path, "w"))
    file:write(assert(yajl.to_string(payload)))
    file:close()

    reload_stub = stub(agnosticdb.highlights, "reload", function() end)

    local stats, err = agnosticdb.transfer.importData(path)

    assert.is_nil(err)
    assert.is_not_nil(stats)
    assert.are.equal(path, stats.path)
    assert.are.equal(1, stats.imported)
    assert.are.equal(1, stats.skipped)
    assert.stub(reload_stub).was.called(1)

    local person = agnosticdb.db.get_person("Imported")
    assert.is_not_nil(person)
    assert.are.equal("Imported", person.name)
    assert.are.equal("Cyrene", person.city)
    assert.are.equal("Bard", person.class)
    assert.are.equal("fresh", person.notes)
    assert.are.equal("ally", person.iff)
  end)
end)
