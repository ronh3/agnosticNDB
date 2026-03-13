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

  it("reports refresh_online progress, summary, and queue completion", function()
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
    agnosticdb.api.on_queue_progress(25, { processed = 1, total = 4 })
    agnosticdb.api.on_queue_done({
      ok = 1,
      unchanged = 0,
      cached = 0,
      pruned = 0,
      api_error = 0,
      decode_failed = 0,
      download_error = 0,
      other = 0,
      elapsed_seconds = 12,
    })

    fetch_online_stub:revert()
    eta_stub:revert()

    local rendered = table.concat(outputs, "")
    assert.is_true(rendered:find("Refreshing online list (force)...", 1, true) ~= nil)
    assert.is_true(rendered:find("Online list: 2 names, 1 added, 2 queued.", 1, true) ~= nil)
    assert.is_true(rendered:find("Estimated completion: ~42s", 1, true) ~= nil)
    assert.is_true(rendered:find("Queue progress: 25%% (1/4)") ~= nil)
    assert.is_true(rendered:find("Queue complete: ok=1 unchanged=0 cached=0 pruned=0 api_error=0 decode_failed=0 download_error=0 other=0", 1, true) ~= nil)
    assert.is_true(rendered:find("Queue time: 12s", 1, true) ~= nil)
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
end)
