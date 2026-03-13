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
end)
