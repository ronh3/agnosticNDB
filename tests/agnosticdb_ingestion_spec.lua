local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb ingestion", function()
  local output_stub
  local reload_stub
  local outputs
  local reload_calls

  before_each(function()
    helper.reset()
    outputs = {}
    reload_calls = 0
    output_stub = stub(agnosticdb.ui, "emit_line", function(text)
      outputs[#outputs + 1] = tostring(text or "")
    end)
  end)

  after_each(function()
    if output_stub then output_stub:revert() end
    if reload_stub then reload_stub:revert() end
    output_stub = nil
    reload_stub = nil
  end)

  it("applies a captured citizens list to the database", function()
    agnosticdb.lists.capture = {
      kind = "citizens_list",
      city = "Ashtan",
      names = {
        Alpha = true,
        Beta = true,
      },
    }

    agnosticdb.lists.finish_capture()

    local alpha = agnosticdb.db.get_person("Alpha")
    local beta = agnosticdb.db.get_person("Beta")

    assert.is_not_nil(alpha)
    assert.is_not_nil(beta)
    assert.are.equal("Ashtan", alpha.city)
    assert.are.equal("citizens_list", alpha.source)
    assert.are.equal("Ashtan", beta.city)
    assert.is_true(table.concat(outputs, "\n"):find("Citizens list updated for Ashtan: 2 listed, 2 set.", 1, true) ~= nil)
  end)

  it("replaces the personal enemy list and clears stale entries", function()
    reload_stub = stub(agnosticdb.highlights, "reload", function()
      reload_calls = reload_calls + 1
    end)

    agnosticdb.db.upsert_person({ name = "Alpha", iff = "enemy" })
    agnosticdb.db.upsert_person({ name = "Beta", iff = "enemy" })

    agnosticdb.enemies.capture = {
      kind = "personal",
      names = {
        Alpha = true,
        Gamma = true,
      },
    }

    agnosticdb.enemies.finish_capture()

    assert.are.equal("enemy", agnosticdb.db.get_person("Alpha").iff)
    assert.are.equal("auto", agnosticdb.db.get_person("Beta").iff)
    assert.are.equal("enemy", agnosticdb.db.get_person("Gamma").iff)
    assert.are.equal(1, reload_calls)
    assert.is_true(table.concat(outputs, "\n"):find("Personal enemies updated: 2 listed, 2 set, 1 cleared.", 1, true) ~= nil)
  end)

  it("replaces a captured city enemy list and clears stale entries", function()
    agnosticdb.db.upsert_person({ name = "Alpha", enemy_city = "Ashtan" })
    agnosticdb.db.upsert_person({ name = "Beta", enemy_city = "Ashtan" })

    agnosticdb.enemies.capture = {
      kind = "city",
      org = "Ashtan",
      names = {
        Alpha = true,
        Gamma = true,
      },
    }

    agnosticdb.enemies.finish_capture()

    assert.are.equal("Ashtan", agnosticdb.db.get_person("Alpha").enemy_city)
    assert.are.equal("", agnosticdb.db.get_person("Beta").enemy_city)
    assert.are.equal("Ashtan", agnosticdb.db.get_person("Gamma").enemy_city)
    assert.is_true(table.concat(outputs, "\n"):find("City enemies updated for Ashtan: 2 listed, 2 set, 1 cleared.", 1, true) ~= nil)
  end)
end)
