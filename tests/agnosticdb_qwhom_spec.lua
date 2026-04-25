local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb qwhom", function()
  local saved_send
  local saved_enableTrigger
  local saved_disableTrigger
  local saved_deleteFull
  local saved_deleteLine
  local saved_mmp
  local output_stub
  local section_stub
  local open_stub
  local close_stub
  local enabled
  local disabled
  local sent
  local deleted_full
  local deleted_line
  local wrapped
  local sections

  local function has_value(list, value)
    for _, item in ipairs(list or {}) do
      if item == value then return true end
    end
    return false
  end

  before_each(function()
    helper.reset()
    agnosticdb.qwhom.data = {}
    agnosticdb.qwhom.dead = {}
    agnosticdb.qwhom.active = false
    agnosticdb.qwhom.filter = nil

    enabled = {}
    disabled = {}
    sent = {}
    deleted_full = 0
    deleted_line = 0
    wrapped = {}
    sections = {}

    saved_send = _G.send
    saved_enableTrigger = _G.enableTrigger
    saved_disableTrigger = _G.disableTrigger
    saved_deleteFull = _G.deleteFull
    saved_deleteLine = _G.deleteLine
    saved_mmp = _G.mmp

    _G.send = function(cmd, echo)
      sent[#sent + 1] = { cmd = cmd, echo = echo }
    end
    _G.enableTrigger = function(name)
      enabled[#enabled + 1] = name
    end
    _G.disableTrigger = function(name)
      disabled[#disabled + 1] = name
    end
    _G.deleteFull = function()
      deleted_full = deleted_full + 1
    end
    _G.deleteLine = function()
      deleted_line = deleted_line + 1
    end
    _G.mmp = nil

    open_stub = stub(agnosticdb.ui, "report_frame_open", function(title)
      wrapped[#wrapped + 1] = "open:" .. tostring(title)
    end)
    close_stub = stub(agnosticdb.ui, "report_frame_close", function()
      wrapped[#wrapped + 1] = "close"
    end)
    section_stub = stub(agnosticdb.ui, "report_section", function(label, count)
      sections[#sections + 1] = { label = label, count = count }
    end)
    output_stub = stub(agnosticdb.ui, "report_wrapped", function(text)
      wrapped[#wrapped + 1] = tostring(text or "")
    end)
  end)

  after_each(function()
    if output_stub then output_stub:revert() end
    if section_stub then section_stub:revert() end
    if open_stub then open_stub:revert() end
    if close_stub then close_stub:revert() end
    output_stub = nil
    section_stub = nil
    open_stub = nil
    close_stub = nil

    _G.send = saved_send
    _G.enableTrigger = saved_enableTrigger
    _G.disableTrigger = saved_disableTrigger
    _G.deleteFull = saved_deleteFull
    _G.deleteLine = saved_deleteLine
    _G.mmp = saved_mmp
  end)

  it("starts capture with triggers and queued who command", function()
    agnosticdb.qwhom.data = { stale = true }
    agnosticdb.qwhom.dead = { "Old" }

    agnosticdb.qwhom.start("  Market ")

    assert.is_true(agnosticdb.qwhom.active)
    assert.are.equal("market", agnosticdb.qwhom.filter)
    assert.are.same({}, agnosticdb.qwhom.data)
    assert.are.same({}, agnosticdb.qwhom.dead)
    assert.is_true(has_value(enabled, "Qwhom Capture"))
    assert.is_true(has_value(enabled, "Qwhom Display"))
    assert.is_true(has_value(enabled, "Qwhom Prompt"))
    assert.are.equal(1, #sent)
    assert.are.equal("queue add free who b", sent[1].cmd)
    assert.is_false(sent[1].echo)
  end)

  it("ignores queue noise and header lines while active", function()
    agnosticdb.qwhom.start()

    agnosticdb.qwhom.capture_line("[System]: Added WHO B to your free queue.", "")
    agnosticdb.qwhom.capture_line("[System]: Running queued free command: WHO B", "")
    agnosticdb.qwhom.capture_line("queue add free who b", "")
    agnosticdb.qwhom.capture_line("Name          Location", "")
    agnosticdb.qwhom.capture_line("----          --------", "")
    agnosticdb.qwhom.capture_line("Total: 0", "")

    assert.are.same({}, agnosticdb.qwhom.data)
    assert.are.same({}, agnosticdb.qwhom.dead)
    assert.is_true(deleted_full >= 6)
  end)

  it("captures gemmed/off-plane and dead entries without mapper data", function()
    agnosticdb.db.upsert_person({ name = "Alpha", city = "Ashtan" })
    agnosticdb.qwhom.start()

    agnosticdb.qwhom.capture_line("Alpha", "")
    agnosticdb.qwhom.capture_line("(Embracing Death) beta", "")

    local area = agnosticdb.qwhom.data["Unknown Area"]
    assert.is_not_nil(area)
    assert.are.equal(1, #area["Gemmed or Off-Plane"])
    assert.are.equal("Alpha", area["Gemmed or Off-Plane"][1].name)
    assert.are.same({ "Beta" }, agnosticdb.qwhom.dead)
  end)

  it("uses mapper APIs to group located entries by area when available", function()
    _G.mmp = {
      searchRoomExact = function(where)
        assert.are.equal("Central Market", where)
        return { [12345] = true }
      end,
      getAreaName = function(room)
        assert.are.equal(12345, room)
        return "Hashan"
      end,
    }

    agnosticdb.qwhom.start()
    agnosticdb.qwhom.capture_line("alpha", "Central Market")

    local area = agnosticdb.qwhom.data.Hashan
    assert.is_not_nil(area)
    assert.are.equal(1, #area["Central Market"])
    assert.are.equal("Alpha", area["Central Market"][1].name)
  end)

  it("finishes by rendering anchors, disabling triggers, and clearing state", function()
    agnosticdb.qwhom.start()
    agnosticdb.qwhom.capture_line("Alpha", "Central Market")
    agnosticdb.qwhom.capture_line("(Embracing Death) Beta", "")

    agnosticdb.qwhom.finish()

    assert.is_false(agnosticdb.qwhom.active)
    assert.is_nil(agnosticdb.qwhom.filter)
    assert.are.same({}, agnosticdb.qwhom.data)
    assert.are.same({}, agnosticdb.qwhom.dead)
    assert.are.equal(1, deleted_line)
    assert.is_true(has_value(disabled, "Qwhom Capture"))
    assert.is_true(has_value(disabled, "Qwhom Display"))
    assert.is_true(has_value(disabled, "Qwhom Prompt"))

    local rendered = table.concat(wrapped, "\n")
    assert.is_true(rendered:find("open:Qwhom", 1, true) ~= nil)
    assert.is_true(rendered:find("Central Market", 1, true) ~= nil)
    assert.is_true(rendered:find("Alpha", 1, true) ~= nil)
    assert.is_true(rendered:find("Beta", 1, true) ~= nil)
    assert.is_true(rendered:find("close", 1, true) ~= nil)
    assert.is_true(#sections >= 2)
  end)

  it("renders a no entries message when filters exclude all captured areas", function()
    agnosticdb.qwhom.start("Hashan")
    agnosticdb.qwhom.capture_line("Alpha", "")

    agnosticdb.qwhom.finish()

    local rendered = table.concat(wrapped, "\n")
    assert.is_true(rendered:find("No qwhom entries.", 1, true) ~= nil)
  end)
end)
