local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb honors", function()
  local output_stub
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
    output_stub = nil
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
        "He serves as (7) in the army of Ashtan.",
        "He is an Immortal.",
        "He is a mighty Dragon.",
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
    assert.are.equal(1, tonumber(person.immortal))
    assert.are.equal(1, tonumber(person.dragon))
    assert.is_true(table.concat(outputs, "\n"):find("Honors updated for Testperson.", 1, true) ~= nil)
  end)
end)
