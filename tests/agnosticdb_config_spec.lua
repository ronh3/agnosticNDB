local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb config", function()
  local reload_stub
  local reload_calls
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
    reload_calls = 0
    temp_paths = {}
  end)

  after_each(function()
    if reload_stub then reload_stub:revert() end
    reload_stub = nil

    for _, path in ipairs(temp_paths or {}) do
      os.remove(path)
    end
  end)

  it("exports config settings to json", function()
    agnosticdb.conf.api.min_refresh_hours = 12
    agnosticdb.conf.honors.delay_seconds = 4
    agnosticdb.conf.theme.name = "custom"
    agnosticdb.conf.ui.quiet_mode = true

    local path = temp_json_path("agnosticdb-config-export-spec")
    local result, err = agnosticdb.config.export_settings(path)

    if not has_json_support() then
      assert.is_nil(result)
      assert.are.equal("json_unavailable", err)
      return
    end

    assert.is_nil(err)
    assert.is_not_nil(result)
    assert.are.equal(path, result.path)

    local file = assert(io.open(path, "r"))
    local payload = file:read("*a")
    file:close()

    assert.is_true(payload:find('"version":1', 1, true) ~= nil)
    assert.is_true(payload:find('"config"', 1, true) ~= nil)
    assert.is_true(payload:find('"min_refresh_hours":12', 1, true) ~= nil)
    assert.is_true(payload:find('"delay_seconds":4', 1, true) ~= nil)
    assert.is_true(payload:find('"quiet_mode":true', 1, true) ~= nil)
  end)

  it("imports config settings and reloads highlights", function()
    local path = temp_json_path("agnosticdb-config-import-spec")

    if not has_json_support() then
      local result, err = agnosticdb.config.import_settings(path)
      assert.is_nil(result)
      assert.are.equal("json_unavailable", err)
      return
    end

    local file = assert(io.open(path, "w"))
    file:write([[{"config":{"api":{"min_refresh_hours":6,"announce_changes_only":true},"honors":{"delay_seconds":3},"theme":{"name":"ocean"},"highlights_enabled":true,"prune_dormant":true,"ui":{"quiet_mode":true},"highlight":{"enemies":{"underline":false},"cities":{"ashtan":{"color":"blue"}}},"highlight_ignore":{"alpha":true}}}]])
    file:close()

    reload_stub = stub(agnosticdb.highlights, "reload", function()
      reload_calls = reload_calls + 1
    end)

    local result, err = agnosticdb.config.import_settings(path)

    assert.is_nil(err)
    assert.is_not_nil(result)
    assert.are.equal(path, result.path)
    assert.are.equal(6, agnosticdb.conf.api.min_refresh_hours)
    assert.is_true(agnosticdb.conf.api.announce_changes_only)
    assert.are.equal(3, agnosticdb.conf.honors.delay_seconds)
    assert.are.equal("ocean", agnosticdb.conf.theme.name)
    assert.is_true(agnosticdb.conf.highlights_enabled)
    assert.is_true(agnosticdb.conf.prune_dormant)
    assert.is_true(agnosticdb.conf.ui.quiet_mode)
    assert.is_false(agnosticdb.conf.highlight.enemies.underline)
    assert.are.equal("blue", agnosticdb.conf.highlight.cities.ashtan.color)
    assert.is_true(agnosticdb.conf.highlight_ignore.alpha)
    assert.are.equal(1, reload_calls)
  end)
end)
