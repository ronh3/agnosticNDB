local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb ingestion", function()
  local output_stub
  local reload_stub
  local fetch_list_stub
  local outputs
  local reload_calls
  local saved_tempRegexTrigger
  local saved_tempPromptTrigger
  local saved_killTrigger
  local saved_isPrompt
  local saved_line

  before_each(function()
    helper.reset()
    outputs = {}
    reload_calls = 0
    saved_tempRegexTrigger = _G.tempRegexTrigger
    saved_tempPromptTrigger = _G.tempPromptTrigger
    saved_killTrigger = _G.killTrigger
    saved_isPrompt = _G.isPrompt
    saved_line = _G.line
    output_stub = stub(agnosticdb.ui, "emit_line", function(text)
      outputs[#outputs + 1] = tostring(text or "")
    end)
  end)

  after_each(function()
    if output_stub then output_stub:revert() end
    if reload_stub then reload_stub:revert() end
    if fetch_list_stub then fetch_list_stub:revert() end
    output_stub = nil
    reload_stub = nil
    fetch_list_stub = nil
    _G.tempRegexTrigger = saved_tempRegexTrigger
    _G.tempPromptTrigger = saved_tempPromptTrigger
    _G.killTrigger = saved_killTrigger
    _G.isPrompt = saved_isPrompt
    _G.line = saved_line
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

  it("preserves an existing non-empty source when applying citizens data", function()
    agnosticdb.db.upsert_person({
      name = "Alpha",
      city = "Cyrene",
      source = "api",
    })

    agnosticdb.lists.capture = {
      kind = "citizens_list",
      city = "Ashtan",
      names = {
        Alpha = true,
      },
    }

    agnosticdb.lists.finish_capture()

    local alpha = agnosticdb.db.get_person("Alpha")
    assert.are.equal("Ashtan", alpha.city)
    assert.are.equal("api", alpha.source)
  end)

  it("parses class rows from captured list tables and skips ambiguous names", function()
    local line_callback
    local killed = {}

    agnosticdb.db.upsert_person({ name = "Alpha" })
    agnosticdb.db.upsert_person({ name = "Beta" })

    fetch_list_stub = stub(agnosticdb.api, "fetch_list", function(on_done)
      agnosticdb.api.last_list_names = { "Alpha", "Beta" }
      on_done({ "Alpha", "Beta" }, "ok")
    end)
    _G.tempRegexTrigger = function(_, fn)
      line_callback = fn
      return "list-line-trigger"
    end
    _G.tempPromptTrigger = function()
      return "list-prompt-trigger"
    end
    _G.killTrigger = function(id)
      killed[#killed + 1] = id
    end
    _G.isPrompt = function()
      return false
    end

    agnosticdb.lists.capture_table("cwho")

    assert.is_function(line_callback)
    _G.line = "Citizen              Rank    Class"
    line_callback()
    _G.line = "Alpha                1       Magi"
    line_callback()
    _G.line = "Not Alpha Beta       1       Bard"
    line_callback()
    _G.line = "Beta                 2       monk"
    line_callback()

    agnosticdb.lists.finish_capture()

    assert.are.equal("Magi", agnosticdb.db.get_person("Alpha").class)
    assert.are.equal("Monk", agnosticdb.db.get_person("Beta").class)
    assert.are.same({ "list-line-trigger", "list-prompt-trigger" }, killed)
    assert.is_true(table.concat(outputs, "\n"):find("List capture (cwho) complete: 2 updated, 1 skipped.", 1, true) ~= nil)
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

  it("sets and clears personal enemy overrides through direct helpers", function()
    reload_stub = stub(agnosticdb.highlights, "reload", function()
      reload_calls = reload_calls + 1
    end)

    agnosticdb.db.upsert_person({ name = "Alpha", iff = "ally" })
    agnosticdb.db.upsert_person({ name = "Beta", iff = "enemy" })
    agnosticdb.db.upsert_person({ name = "Gamma", iff = "enemy" })

    agnosticdb.enemies.set_personal("alpha", true)
    assert.are.equal("enemy", agnosticdb.db.get_person("Alpha").iff)

    agnosticdb.enemies.set_personal("Alpha", false)
    assert.are.equal("auto", agnosticdb.db.get_person("Alpha").iff)

    agnosticdb.enemies.clear_personal()

    assert.are.equal("auto", agnosticdb.db.get_person("Beta").iff)
    assert.are.equal("auto", agnosticdb.db.get_person("Gamma").iff)
    assert.are.equal(3, reload_calls)
    assert.is_true(table.concat(outputs, "\n"):find("Personal enemies cleared: 2.", 1, true) ~= nil)
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

  it("replaces a captured house enemy list and clears stale entries", function()
    agnosticdb.db.upsert_person({ name = "Alpha", enemy_house = "Scions" })
    agnosticdb.db.upsert_person({ name = "Beta", enemy_house = "Scions" })

    agnosticdb.enemies.capture = {
      kind = "house",
      org = "Scions",
      names = {
        Alpha = true,
        Gamma = true,
      },
    }

    agnosticdb.enemies.finish_capture()

    assert.are.equal("Scions", agnosticdb.db.get_person("Alpha").enemy_house)
    assert.are.equal("", agnosticdb.db.get_person("Beta").enemy_house)
    assert.are.equal("Scions", agnosticdb.db.get_person("Gamma").enemy_house)
    assert.is_true(table.concat(outputs, "\n"):find("House enemies updated for Scions: 2 listed, 2 set, 1 cleared.", 1, true) ~= nil)
  end)
end)
