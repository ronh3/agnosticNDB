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
end)
