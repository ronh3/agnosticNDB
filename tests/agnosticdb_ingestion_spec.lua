local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb ingestion", function()
  local output_stub
  local reload_stub
  local api_stub
  local regex_stub
  local prompt_stub
  local kill_stub
  local saved_isPrompt
  local outputs
  local regex_callback
  local prompt_callback

  before_each(function()
    helper.reset()
    outputs = {}
    regex_callback = nil
    prompt_callback = nil
    saved_isPrompt = _G.isPrompt
    output_stub = stub(agnosticdb.ui, "emit_line", function(text)
      outputs[#outputs + 1] = tostring(text or "")
    end)
  end)

  after_each(function()
    if output_stub then output_stub:revert() end
    if reload_stub then reload_stub:revert() end
    if api_stub then api_stub:revert() end
    if regex_stub then regex_stub:revert() end
    if prompt_stub then prompt_stub:revert() end
    if kill_stub then kill_stub:revert() end
    _G.isPrompt = saved_isPrompt
    line = nil
    output_stub = nil
    reload_stub = nil
    api_stub = nil
    regex_stub = nil
    prompt_stub = nil
    kill_stub = nil
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
    assert.are.equal("Ashtan", alpha.city)
    assert.are.equal("citizens_list", alpha.source)
    assert.are.equal("Ashtan", beta.city)
    assert.is_true(table.concat(outputs, "\n"):find("Citizens list updated for Ashtan: 2 listed, 2 set.", 1, true) ~= nil)
  end)

  it("parses captured table rows into class updates", function()
    api_stub = stub(agnosticdb.api, "fetch_list", function(callback)
      callback({ "Alpha" }, "ok")
    end)
    regex_stub = stub(_G, "tempRegexTrigger", function(_, callback)
      regex_callback = callback
      return 101
    end)
    prompt_stub = stub(_G, "tempPromptTrigger", function(callback)
      prompt_callback = callback
      return 102
    end)
    kill_stub = stub(_G, "killTrigger", function() end)
    _G.isPrompt = function() return false end

    agnosticdb.db.upsert_person({ name = "Alpha" })
    agnosticdb.lists.capture_table("qwho")

    line = "Citizen        Info        Class"
    regex_callback()
    line = "Alpha, the Example        Active        Magi"
    regex_callback()
    prompt_callback()

    local person = agnosticdb.db.get_person("Alpha")
    assert.are.equal("Magi", person.class)
    assert.is_true(table.concat(outputs, "\n"):find("List capture (qwho) complete: 1 updated, 0 skipped.", 1, true) ~= nil)
  end)

  it("replaces the personal enemy list and clears stale entries", function()
    reload_stub = stub(agnosticdb.highlights, "reload", function() end)
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
    assert.stub(reload_stub).was.called(1)
    assert.is_true(table.concat(outputs, "\n"):find("Personal enemies updated: 2 listed, 2 set, 1 cleared.", 1, true) ~= nil)
  end)
end)
