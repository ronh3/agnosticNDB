local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb db", function()
  local save_stub

  before_each(function()
    helper.reset()
    save_stub = stub(agnosticdb.config, "save", function() end)
  end)

  after_each(function()
    if save_stub then
      save_stub:revert()
      save_stub = nil
    end
  end)

  it("stores normalized people and preserves last_updated for unchanged writes", function()
    local changed, person = agnosticdb.db.upsert_person({
      name = "testperson",
      class = "Magi",
      city = "Ashtan",
      notes = "hello",
    })

    assert.is_true(changed)
    assert.are.equal("Testperson", person.name)
    assert.are.equal("Magi", person.class)
    assert.are.equal("Ashtan", person.city)
    assert.are.equal("hello", person.notes)
    assert.is_true((tonumber(person.last_updated) or 0) > 0)

    local first_updated = tonumber(person.last_updated)
    local changed_again, again = agnosticdb.db.upsert_person({
      name = "Testperson",
      class = "Magi",
      city = "Ashtan",
      notes = "hello",
    })

    assert.is_false(changed_again)
    assert.are.equal(first_updated, tonumber(again.last_updated))
  end)

  it("derives enemy status from politics and respects iff overrides", function()
    agnosticdb.politics.set_city_relation("Ashtan", "enemy")
    agnosticdb.db.upsert_person({ name = "Enemycandidate", city = "Ashtan", iff = "auto" })

    assert.is_true(agnosticdb.iff.is_enemy("Enemycandidate"))

    agnosticdb.iff.set("Enemycandidate", "ally")

    assert.is_false(agnosticdb.iff.is_enemy("Enemycandidate"))
  end)
end)
