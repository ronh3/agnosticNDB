local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb honors", function()
  before_each(function()
    helper.reset()
  end)

  it("stores a basic honors capture without errors", function()
    local finished = false

    agnosticdb.honors.active = {
      name = "testperson",
      lines = {
        "Testperson, Example of Ashtan",
        "He is a Magi of Ashtan.",
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
    assert.are.equal("Magi", person.class)
    assert.are.equal("Ashtan", person.city)
  end)
end)
