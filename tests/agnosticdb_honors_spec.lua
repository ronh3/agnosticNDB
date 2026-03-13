local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb honors", function()
  local output_stub
  local run_queue_stub
  local outputs

  before_each(function()
    helper.reset()
    outputs = {}
    output_stub = stub(agnosticdb.ui, "emit_line", function(text)
      outputs[#outputs + 1] = tostring(text or "")
    end)
  end)

  after_each(function()
    if output_stub then output_stub:revert() end
    if run_queue_stub then run_queue_stub:revert() end
    output_stub = nil
    run_queue_stub = nil
  end)

  it("exposes the honors entry points", function()
    assert.is_table(agnosticdb.honors)
    assert.is_function(agnosticdb.honors.capture)
    assert.is_function(agnosticdb.honors.finish_capture)
    assert.is_function(agnosticdb.honors.queue_names)
    assert.is_function(agnosticdb.honors.cancel_queue)
  end)

  it("stores a basic honors capture", function()
    local finished = false

    agnosticdb.honors.active = {
      name = "testperson",
      lines = {
        "Testperson, Example of Ashtan",
        "He is a Magi of Ashtan.",
        "He is a member of the House of Scions.",
        "He is ranked 5 in the city and ranked 123 overall.",
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
    assert.are.equal(5, tonumber(person.city_rank))
    assert.are.equal(123, tonumber(person.xp_rank))
    assert.is_true(table.concat(outputs, "\n"):find("Honors updated for Testperson.", 1, true) ~= nil)
  end)

  it("extracts race, army rank, immortal, and dragon flags from honors", function()
    agnosticdb.honors.active = {
      name = "fieldperson",
      lines = {
        "Fieldperson, the Eternal (male atavian)",
        "He is a Bard of Cyrene.",
        "He is a member of the House of Scions.",
        "He is (12) in the army of Cyrene.",
        "He is an Immortal.",
        "He is also a red dragon.",
      },
    }

    agnosticdb.honors.finish_capture()

    local person = agnosticdb.db.get_person("Fieldperson")
    assert.is_not_nil(person)
    assert.are.equal("Atavian", person.race)
    assert.are.equal(12, tonumber(person.army_rank))
    assert.are.equal(1, tonumber(person.immortal))
    assert.are.equal(1, tonumber(person.dragon))
    assert.are.equal("Bard", person.class)
    assert.are.equal("Cyrene", person.city)
  end)

  it("deduplicates names when starting an honors queue", function()
    local ran_queue = 0
    local on_done = function() end

    run_queue_stub = stub(agnosticdb.honors, "run_queue", function()
      ran_queue = ran_queue + 1
    end)

    agnosticdb.honors.queue_names({ "testperson", "TESTPERSON", "otherperson" }, on_done, { announce = true })

    assert.is_true(agnosticdb.honors.queue_running)
    assert.are.same({ "Testperson", "Otherperson" }, agnosticdb.honors.queue)
    assert.are.equal(2, agnosticdb.honors.queue_stats.total)
    assert.are.equal(0, agnosticdb.honors.queue_stats.processed)
    assert.are.equal(on_done, agnosticdb.honors.queue_on_done)
    assert.are.equal(1, ran_queue)
    assert.is_true(table.concat(outputs, "\n"):find("Honors queue: 2 names.", 1, true) ~= nil)
  end)

  it("cancels honors queue state cleanly", function()
    agnosticdb.honors.queue = { "Testperson", "Otherperson" }
    agnosticdb.honors.queue_running = true
    agnosticdb.honors.queue_stats = { total = 2, processed = 1 }
    agnosticdb.honors.queue_on_done = function() end
    agnosticdb.honors.queue_opts = { announce = true }

    agnosticdb.honors.cancel_queue()

    assert.are.same({}, agnosticdb.honors.queue)
    assert.is_false(agnosticdb.honors.queue_running)
    assert.is_nil(agnosticdb.honors.queue_stats)
    assert.is_nil(agnosticdb.honors.queue_on_done)
    assert.is_nil(agnosticdb.honors.queue_opts)
  end)
end)
