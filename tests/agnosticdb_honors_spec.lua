local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb honors", function()
  local output_stub
  local capture_stub
  local timer_stub
  local send_stub
  local outputs
  local timers
  local sent

  before_each(function()
    helper.reset()
    outputs = {}
    timers = {}
    sent = {}
    output_stub = stub(agnosticdb.ui, "emit_line", function(text)
      outputs[#outputs + 1] = tostring(text or "")
    end)
  end)

  after_each(function()
    if output_stub then output_stub:revert() end
    if capture_stub then capture_stub:revert() end
    if timer_stub then timer_stub:revert() end
    if send_stub then send_stub:revert() end
    output_stub = nil
    capture_stub = nil
    timer_stub = nil
    send_stub = nil
  end)

  it("parses honors lines into a person record", function()
    local finished = false
    agnosticdb.honors.active = {
      name = "testperson",
      lines = {
        "Testperson, Example of Ashtan",
        "He is a Magi of Ashtan.",
        "He is a member of the House of Scions.",
        "He is ranked 5 in the city and ranked 123 overall.",
        "He serves as (7) in the army of Ashtan.",
        "He is a mighty Dragon.",
        "He is an Immortal.",
        "He is a (male rajamala).",
      },
      on_finish = function()
        finished = true
      end,
    }

    agnosticdb.honors.finish_capture()

    local person = agnosticdb.db.get_person("Testperson")
    assert.is_true(finished)
    assert.is_not_nil(person)
    assert.are.equal("Testperson", person.name)
    assert.are.equal("Testperson, Example of Ashtan", person.title)
    assert.are.equal("Magi", person.class)
    assert.are.equal("Ashtan", person.city)
    assert.are.equal("Scions", person.house)
    assert.are.equal("Rajamala", person.race)
    assert.are.equal(5, tonumber(person.city_rank))
    assert.are.equal(123, tonumber(person.xp_rank))
    assert.are.equal(7, tonumber(person.army_rank))
    assert.are.equal(1, tonumber(person.dragon))
    assert.are.equal(1, tonumber(person.immortal))
    assert.is_true(table.concat(outputs, "\n"):find("Honors updated for Testperson.", 1, true) ~= nil)
  end)

  it("queues unique honors requests and reports completion stats", function()
    local capture_calls = {}
    local done_stats

    capture_stub = stub(agnosticdb.honors, "capture", function(name, on_finish, opts)
      capture_calls[#capture_calls + 1] = {
        name = name,
        on_finish = on_finish,
        opts = opts,
      }
    end)
    timer_stub = stub(_G, "tempTimer", function(delay, fn)
      timers[#timers + 1] = { delay = delay, fn = fn }
      return #timers
    end)
    send_stub = stub(_G, "send", function(cmd)
      sent[#sent + 1] = cmd
    end)

    agnosticdb.honors.queue_names({ "testperson", "TESTPERSON", "otherperson" }, function(stats)
      done_stats = stats
    end, { announce = true })

    assert.are.equal(1, #capture_calls)
    assert.are.equal("Testperson", capture_calls[1].name)
    assert.is_true(capture_calls[1].opts.announce)
    assert.are.same({ "HONORS Testperson" }, sent)

    capture_calls[1].on_finish()
    assert.are.equal(1, #timers)
    assert.are.equal(0, timers[1].delay)

    timers[1].fn()
    assert.are.equal(2, #capture_calls)
    assert.are.equal("Otherperson", capture_calls[2].name)
    assert.are.same({ "HONORS Testperson", "HONORS Otherperson" }, sent)

    capture_calls[2].on_finish()

    assert.is_not_nil(done_stats)
    assert.are.equal(2, done_stats.total)
    assert.are.equal(2, done_stats.processed)
    assert.is_false(agnosticdb.honors.queue_running)
    assert.is_true(table.concat(outputs, "\n"):find("Honors queue complete: 2 processed", 1, true) ~= nil)
  end)
end)
