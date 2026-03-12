local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb qwhom", function()
  local send_stub
  local enable_stub
  local disable_stub
  local delete_line_stub
  local cecho_stub
  local open_stub
  local close_stub
  local enabled
  local disabled
  local sent

  before_each(function()
    helper.reset()
    agnosticdb.qwhom.data = {}
    agnosticdb.qwhom.dead = {}
    agnosticdb.qwhom.active = false
    agnosticdb.qwhom.filter = nil
    enabled = {}
    disabled = {}
    sent = {}

    send_stub = stub(_G, "send", function(cmd)
      sent[#sent + 1] = cmd
    end)
    enable_stub = stub(_G, "enableTrigger", function(name)
      enabled[#enabled + 1] = name
    end)
    disable_stub = stub(_G, "disableTrigger", function(name)
      disabled[#disabled + 1] = name
    end)
    delete_line_stub = stub(_G, "deleteLine", function() end)
    cecho_stub = stub(_G, "cecho", function() end)
    open_stub = stub(agnosticdb.ui, "report_frame_open", function() end)
    close_stub = stub(agnosticdb.ui, "report_frame_close", function() end)
  end)

  after_each(function()
    if send_stub then send_stub:revert() end
    if enable_stub then enable_stub:revert() end
    if disable_stub then disable_stub:revert() end
    if delete_line_stub then delete_line_stub:revert() end
    if cecho_stub then cecho_stub:revert() end
    if open_stub then open_stub:revert() end
    if close_stub then close_stub:revert() end
    send_stub = nil
    enable_stub = nil
    disable_stub = nil
    delete_line_stub = nil
    cecho_stub = nil
    open_stub = nil
    close_stub = nil
  end)

  it("starts qwhom capture with triggers and queue command", function()
    agnosticdb.qwhom.start("  un ")

    assert.is_true(agnosticdb.qwhom.active)
    assert.are.equal("un", agnosticdb.qwhom.filter)
    assert.are.same({
      "Qwhom Capture",
      "Qwhom Display",
      "Qwhom Prompt",
    }, enabled)
    assert.are.same({ "queue add free who b" }, sent)
  end)

  it("captures grouped live and dead entries", function()
    agnosticdb.db.upsert_person({ name = "Alpha", city = "Ashtan" })
    agnosticdb.qwhom.start()
    agnosticdb.qwhom.capture_line("Alpha", "")
    agnosticdb.qwhom.capture_line("(Embracing Death) Beta", "")

    assert.are.equal(1, #agnosticdb.qwhom.data["Unknown Area"]["Gemmed or Off-Plane"])
    assert.are.equal("Alpha", agnosticdb.qwhom.data["Unknown Area"]["Gemmed or Off-Plane"][1].name)
    assert.are.same({ "Beta" }, agnosticdb.qwhom.dead)
  end)

  it("clears qwhom state on finish", function()
    agnosticdb.qwhom.start()
    agnosticdb.qwhom.capture_line("Alpha", "")
    agnosticdb.qwhom.capture_line("(Embracing Death) Beta", "")

    agnosticdb.qwhom.finish()

    assert.is_false(agnosticdb.qwhom.active)
    assert.are.same({
      "Qwhom Capture",
      "Qwhom Display",
      "Qwhom Prompt",
    }, disabled)
    assert.are.same({}, agnosticdb.qwhom.data)
    assert.are.same({}, agnosticdb.qwhom.dead)
    assert.is_nil(agnosticdb.qwhom.filter)
  end)
end)
