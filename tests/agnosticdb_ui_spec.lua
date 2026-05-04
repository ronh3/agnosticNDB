local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb ui", function()
  local outputs
  local saved_cecho
  local saved_getWindowWrap
  local saved_line
  local saved_send

  before_each(function()
    helper.reset()
    outputs = {}
    saved_cecho = _G.cecho
    saved_getWindowWrap = _G.getWindowWrap
    saved_line = _G.line
    saved_send = _G.send
    _G.cecho = function(msg)
      outputs[#outputs + 1] = tostring(msg or "")
    end
  end)

  after_each(function()
    _G.cecho = saved_cecho
    _G.getWindowWrap = saved_getWindowWrap
    _G.line = saved_line
    _G.send = saved_send
  end)

  it("renders status with current database information", function()
    agnosticdb.db.upsert_person({ name = "Testperson", class = "Magi", city = "Ashtan" })

    agnosticdb.ui.show_status()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("agnosticDB Status", 1, true) ~= nil)
    assert.is_true(rendered:find("DB ready", 1, true) ~= nil)
    assert.is_true(rendered:find("Rows", 1, true) ~= nil)
    assert.is_true(rendered:find("1", 1, true) ~= nil)
    assert.is_true(rendered:find("API queue", 1, true) ~= nil)
  end)

  it("renders compact help separately from the full command reference", function()
    agnosticdb.ui.show_help()

    local compact = table.concat(outputs, "")
    assert.is_true(compact:find("agnosticDB", 1, true) ~= nil)
    assert.is_true(compact:find("adb status", 1, true) ~= nil)
    assert.is_true(compact:find("adb help", 1, true) ~= nil)
    assert.is_true(compact:find("adb dbreset", 1, true) == nil)

    outputs = {}
    agnosticdb.ui.show_commands()

    local full = table.concat(outputs, "")
    assert.is_true(full:find("agnosticDB Commands", 1, true) ~= nil)
    assert.is_true(full:find("adb", 1, true) ~= nil)
    assert.is_true(full:find("compact jump menu", 1, true) ~= nil)
    assert.is_true(full:find("adb dbreset", 1, true) ~= nil)
  end)

  it("renders stats as a fully framed report", function()
    _G.getWindowWrap = function()
      return 48
    end

    agnosticdb.db.upsert_person({ name = "Alpha", class = "Magi", city = "Ashtan", race = "Human" })
    agnosticdb.db.upsert_person({ name = "Beta", class = "Monk", city = "Cyrene", race = "Rajamala" })
    agnosticdb.db.upsert_person({ name = "Gamma", class = "Monk", city = "", race = "" })

    agnosticdb.ui.stats()

    local rendered = table.concat(outputs, "")
    local verticals = select(2, rendered:gsub("║", ""))
    assert.is_true(rendered:find("Stats Summary", 1, true) ~= nil)
    assert.is_true(rendered:find("By class", 1, true) ~= nil)
    assert.is_true(rendered:find("By race", 1, true) ~= nil)
    assert.is_true(rendered:find("Rogue", 1, true) ~= nil)
    assert.is_true(verticals >= 6)
  end)

  it("validates qwp rank input", function()
    agnosticdb.ui.qwp_command("rank")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("qwp rank <n>: missing numeric rank.", 1, true) ~= nil)
  end)

  it("starts framed status output on a new line after prompt text", function()
    _G.line = "Ex:D"

    agnosticdb.ui.emit_line("Prompt-safe frame")

    local rendered = table.concat(outputs, "")
    assert.are.equal("\n", rendered:sub(1, 1))
    assert.is_true(rendered:find("Prompt-safe frame", 1, true) ~= nil)
  end)

  it("sends direct honors commands without command echo", function()
    local sent = {}
    _G.send = function(cmd, echo)
      sent[#sent + 1] = { cmd = cmd, echo = echo }
    end
    local capture_stub = stub(agnosticdb.honors, "capture", function() end)

    agnosticdb.ui.honors("Hogarth")

    capture_stub:revert()
    assert.are.equal(1, #sent)
    assert.are.equal("HONORS Hogarth", sent[1].cmd)
    assert.is_false(sent[1].echo)
  end)

  it("renders qwp grouped online list with class suffixes", function()
    agnosticdb.db.upsert_person({ name = "Alpha", class = "Magi", city = "Ashtan" })
    agnosticdb.db.upsert_person({ name = "Beta", class = "Monk", city = "Cyrene" })

    local fetch_list_stub = stub(agnosticdb.api, "fetch_list", function(on_done)
      on_done({ "Beta", "Alpha" }, "ok")
    end)

    agnosticdb.ui.qwp_command("class")

    fetch_list_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Building online list...", 1, true) ~= nil)
    assert.is_true(rendered:find("Online List", 1, true) ~= nil)
    assert.is_true(rendered:find("Ashtan", 1, true) ~= nil)
    assert.is_true(rendered:find("Cyrene", 1, true) ~= nil)
    assert.is_true(rendered:find("Alpha (MAG)", 1, true) ~= nil)
    assert.is_true(rendered:find("Beta (MNK)", 1, true) ~= nil)
  end)

  it("wraps qwp rows to the current Mudlet window width", function()
    _G.getWindowWrap = function()
      return 34
    end

    agnosticdb.db.upsert_person({ name = "Alpha", class = "Magi", city = "Ashtan" })
    agnosticdb.db.upsert_person({ name = "Beta", class = "Monk", city = "Ashtan" })
    agnosticdb.db.upsert_person({ name = "Gamma", class = "Bard", city = "Ashtan" })
    agnosticdb.db.upsert_person({ name = "Delta", class = "Serpent", city = "Ashtan" })

    local fetch_list_stub = stub(agnosticdb.api, "fetch_list", function(on_done)
      on_done({ "Alpha", "Beta", "Gamma", "Delta" }, "ok")
    end)

    agnosticdb.ui.qwp_command("class")

    fetch_list_stub:revert()

    local rendered = table.concat(outputs, "")
    local verticals = select(2, rendered:gsub("║", ""))
    assert.is_true(rendered:find("╔", 1, true) ~= nil)
    assert.is_true(rendered:find("╚", 1, true) ~= nil)
    assert.is_true(rendered:find("Alpha (MAG)", 1, true) ~= nil)
    assert.is_true(verticals >= 4)
  end)

  it("reports api queue cancellation and pending count", function()
    agnosticdb.api.queue = { "Alpha", "Beta" }
    local cancel_stub = stub(agnosticdb.api, "cancel_queue", function()
      agnosticdb.api.queue = {}
      return 2
    end)

    agnosticdb.ui.api_queue_cancel()

    cancel_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("API queue canceled. Cleared 2 pending item(s).", 1, true) ~= nil)
    assert.is_true(rendered:find("Any in-flight requests will still complete.", 1, true) ~= nil)
  end)

  it("renders qwhom inside the framed report path", function()
    local saved_send = _G.send
    local saved_enable = _G.enableTrigger
    local saved_disable = _G.disableTrigger
    local saved_deleteLine = _G.deleteLine
    local saved_mmp = _G.mmp

    _G.send = function() end
    _G.enableTrigger = function() end
    _G.disableTrigger = function() end
    _G.deleteLine = function() end
    _G.mmp = nil

    agnosticdb.db.upsert_person({ name = "Alpha", city = "Ashtan" })
    agnosticdb.qwhom.start()
    agnosticdb.qwhom.capture_line("[System]: Added WHO B to your free queue.", "")
    agnosticdb.qwhom.capture_line("[System]: Running queued free command: WHO B", "")
    agnosticdb.qwhom.capture_line("queue add free who b", "")
    agnosticdb.qwhom.capture_line("Alpha", "Market")
    agnosticdb.qwhom.capture_line("(Embracing Death) Beta", "")
    agnosticdb.qwhom.finish()

    _G.send = saved_send
    _G.enableTrigger = saved_enable
    _G.disableTrigger = saved_disable
    _G.deleteLine = saved_deleteLine
    _G.mmp = saved_mmp

    local rendered = table.concat(outputs, "")
    local verticals = select(2, rendered:gsub("║", ""))
    assert.is_true(rendered:find("Qwhom", 1, true) ~= nil)
    assert.is_true(rendered:find("Unknown Area", 1, true) ~= nil)
    assert.is_true(rendered:find("Market", 1, true) ~= nil)
    assert.is_true(rendered:find("Dead", 1, true) ~= nil)
    assert.is_true(rendered:find("Beta", 1, true) ~= nil)
    assert.is_true(rendered:find("[System]", 1, true) == nil)
    assert.is_true(rendered:find("queue add free who b", 1, true) == nil)
    assert.is_true(verticals >= 4)
  end)

  it("renders recent updates ordered by newest first", function()
    agnosticdb.db.upsert_person({
      name = "Older",
      class = "Monk",
      city = "Cyrene",
      source = "api",
      last_updated = 100,
    })
    agnosticdb.db.upsert_person({
      name = "Newer",
      class = "Magi",
      city = "Ashtan",
      source = "honors",
      last_updated = 200,
    })

    agnosticdb.ui.show_recent(2)

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Recent Updates (showing 2 of 2)", 1, true) ~= nil)
    assert.is_true(rendered:find("Newer", 1, true) ~= nil)
    assert.is_true(rendered:find("Older", 1, true) ~= nil)
    assert.is_true(rendered:find("Magi", 1, true) ~= nil)
    assert.is_true(rendered:find("Cyrene", 1, true) ~= nil)
    assert.is_true(rendered:find("honors", 1, true) ~= nil)
    assert.is_true(rendered:find("Newer", 1, true) < rendered:find("Older", 1, true))
  end)

  it("reports refresh_online summary and ETA", function()
    local fetch_online_stub = stub(agnosticdb.api, "fetch_online", function(on_done, opts)
      assert.are.same({ force = true }, opts)
      on_done({
        names = { "Alpha", "Beta" },
        added = 1,
        queued = 2,
      }, "ok")
    end)
    local eta_stub = stub(agnosticdb.api, "estimate_queue_seconds", function(extra)
      assert.are.equal(0, extra)
      return 42
    end)

    agnosticdb.ui.refresh_online()

    fetch_online_stub:revert()
    eta_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Refreshing online list (force)...", 1, true) ~= nil)
    assert.is_true(rendered:find("Online list: 2 names, 1 added, 2 queued.", 1, true) ~= nil)
    assert.is_true(rendered:find("Estimated completion: ~42s", 1, true) ~= nil)
  end)

  it("reports quick_update summary and ETA", function()
    local quick_stub = stub(agnosticdb.api, "fetch_online_new", function(on_done)
      on_done({
        names = { "Alpha", "Beta", "Gamma" },
        added = 2,
        queued = 2,
      }, "ok")
    end)
    local eta_stub = stub(agnosticdb.api, "estimate_queue_seconds", function(extra)
      assert.are.equal(0, extra)
      return 7
    end)

    agnosticdb.ui.quick_update()

    quick_stub:revert()
    eta_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Fetching online list (new names only)...", 1, true) ~= nil)
    assert.is_true(rendered:find("Online list: 3 names, 2 new, 2 queued.", 1, true) ~= nil)
    assert.is_true(rendered:find("Estimated completion: ~7s", 1, true) ~= nil)
  end)

  it("toggles the highlight ignore list and reloads highlights", function()
    local reloads = 0
    local reload_stub = stub(agnosticdb.highlights, "reload", function()
      reloads = reloads + 1
    end)

    agnosticdb.ui.toggle_ignore("Alpha")
    agnosticdb.ui.toggle_ignore("Alpha")

    reload_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Alpha added to highlight ignore list.", 1, true) ~= nil)
    assert.is_true(rendered:find("Alpha removed from highlight ignore list.", 1, true) ~= nil)
    assert.are.equal(2, reloads)
  end)

  it("reports iff updates", function()
    agnosticdb.ui.set_iff("Alpha", "friend")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("IFF for Alpha set to friend.", 1, true) ~= nil)
  end)

  it("validates elemental lord input", function()
    agnosticdb.ui.set_elemental_lord("", "air")
    agnosticdb.ui.set_elemental_lord("Alpha", "")
    agnosticdb.ui.set_elemental_lord("Alpha", "steam")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Provide a name.", 1, true) ~= nil)
    assert.is_true(rendered:find("Provide a type: air|earth|fire|water|clear.", 1, true) ~= nil)
    assert.is_true(rendered:find("Elemental type must be air, earth, fire, water, or clear.", 1, true) ~= nil)
  end)

  it("sets and clears elemental lord type", function()
    agnosticdb.ui.set_elemental_lord("Alpha", "fire")
    agnosticdb.ui.set_elemental_lord("Alpha", "clear")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Elemental type for Alpha set to Fire.", 1, true) ~= nil)
    assert.is_true(rendered:find("Elemental type cleared for Alpha.", 1, true) ~= nil)
    assert.are.equal("", agnosticdb.db.get_person("Alpha").elemental_type)
    assert.are.equal("", agnosticdb.db.get_person("Alpha").current_form)
  end)
end)
