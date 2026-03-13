local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb ui", function()
  local outputs
  local saved_cecho

  before_each(function()
    helper.reset()
    outputs = {}
    saved_cecho = _G.cecho
    _G.cecho = function(msg)
      outputs[#outputs + 1] = tostring(msg or "")
    end
  end)

  after_each(function()
    _G.cecho = saved_cecho
  end)

  it("renders help with the core command sections", function()
    agnosticdb.ui.show_help()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("agnosticDB Help", 1, true) ~= nil)
    assert.is_true(rendered:find("adb status", 1, true) ~= nil)
    assert.is_true(rendered:find("adb honors all", 1, true) ~= nil)
    assert.is_true(rendered:find("qwp [opts]", 1, true) ~= nil)
    assert.is_true(rendered:find("adbtest", 1, true) ~= nil)
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

  it("shows qwp usage for help input", function()
    agnosticdb.ui.qwp_command("help")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Usage: qwp [options]", 1, true) ~= nil)
    assert.is_true(rendered:find("Options: c|class, r|race, rc|race+class, cr|class+race, a|army, rank <n>", 1, true) ~= nil)
  end)

  it("validates qwp rank input", function()
    agnosticdb.ui.qwp_command("rank")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("qwp rank <n>: missing numeric rank.", 1, true) ~= nil)
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

  it("reports config export success", function()
    local export_stub = stub(agnosticdb.config, "export_settings", function(path)
      assert.are.equal("/tmp/agnosticdb-config.json", path)
      return { path = path }
    end)

    agnosticdb.ui.config_export("/tmp/agnosticdb-config.json")

    export_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Config exported to /tmp/agnosticdb-config.json.", 1, true) ~= nil)
  end)

  it("validates config import usage", function()
    agnosticdb.ui.config_import("")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Usage: adb config import <path>", 1, true) ~= nil)
  end)

  it("reports transfer export success", function()
    local export_stub = stub(agnosticdb.transfer, "exportData", function(path)
      assert.are.equal("/tmp/agnosticdb-export.json", path)
      return { count = 2, path = path }
    end)

    agnosticdb.ui.exportData("/tmp/agnosticdb-export.json")

    export_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Exported 2 people to /tmp/agnosticdb-export.json.", 1, true) ~= nil)
  end)

  it("maps transfer import errors to user-facing text", function()
    local import_stub = stub(agnosticdb.transfer, "importData", function(path)
      assert.are.equal("/tmp/agnosticdb-import.json", path)
      return nil, "decode_failed"
    end)

    agnosticdb.ui.importData("/tmp/agnosticdb-import.json")

    import_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Import failed: Import decode failed.", 1, true) ~= nil)
  end)

  it("reports note save and display", function()
    agnosticdb.ui.set_note("Alpha", "Test note")
    agnosticdb.ui.show_note("Alpha")

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Notes saved for Alpha.", 1, true) ~= nil)
    assert.is_true(rendered:find("Notes: Alpha", 1, true) ~= nil)
    assert.is_true(rendered:find("Test note", 1, true) ~= nil)
  end)

  it("reports note clearing counts", function()
    agnosticdb.ui.set_note("Alpha", "Test note")
    agnosticdb.ui.clear_note("Alpha")
    agnosticdb.ui.clear_all_notes()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Notes cleared for Alpha.", 1, true) ~= nil)
    assert.is_true(rendered:find("Notes cleared for 0 people.", 1, true) ~= nil)
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

  it("reports fetch usage and ETA", function()
    local eta_stub = stub(agnosticdb.api, "estimate_queue_seconds", function(extra)
      assert.are.equal(0, extra)
      return 5
    end)
    local fetch_stub = stub(agnosticdb.ui, "fetch_and_show", function(name)
      assert.are.equal("Alpha", name)
    end)

    agnosticdb.ui.fetch("")
    agnosticdb.ui.fetch("Alpha")

    fetch_stub:revert()
    eta_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Usage: adb fetch <name>", 1, true) ~= nil)
    assert.is_true(rendered:find("Tip: adb refresh (force online list), adb quick (new online only).", 1, true) ~= nil)
    assert.is_true(rendered:find("Estimated completion: ~5s", 1, true) ~= nil)
  end)
end)
