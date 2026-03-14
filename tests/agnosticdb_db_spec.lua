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
      specialization = "Pyromancy",
      city = "Ashtan",
      notes = "hello",
    })

    assert.is_true(changed)
    assert.are.equal("Testperson", person.name)
    assert.are.equal("Magi", person.class)
    assert.are.equal("Ashtan", person.city)
    assert.are.equal("hello", person.notes)
    assert.are.equal("Pyromancy", agnosticdb.db.get_current_specialization("Testperson"))
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

  it("preserves unspecified fields while updating changed values", function()
    local _, original = agnosticdb.db.upsert_person({
      name = "Mergeperson",
      class = "Magi",
      city = "Ashtan",
      notes = "keep me",
      iff = "ally",
      source = "manual",
      last_updated = 100,
      last_checked = 50,
    })

    local changed, merged = agnosticdb.db.upsert_person({
      name = "Mergeperson",
      class = "Bard",
      source = "api",
    })

    assert.is_true(changed)
    assert.are.equal("Bard", merged.class)
    assert.are.equal("Ashtan", merged.city)
    assert.are.equal("keep me", merged.notes)
    assert.are.equal("ally", merged.iff)
    assert.are.equal("api", merged.source)
    assert.is_true(tonumber(merged.last_updated) > tonumber(original.last_updated))
    assert.are.equal(tonumber(original.last_checked), tonumber(merged.last_checked))
  end)

  it("allows explicit default-like values to clear stored fields", function()
    agnosticdb.db.upsert_person({
      name = "Clearperson",
      notes = "remove me",
      city_rank = 9,
      current_form = "Elemental",
      elemental_type = "Fire",
    })

    local changed, cleared = agnosticdb.db.upsert_person({
      name = "Clearperson",
      notes = "",
      city_rank = -1,
      current_form = "",
      elemental_type = "",
    })

    assert.is_true(changed)
    assert.are.equal("", cleared.notes)
    assert.are.equal(-1, tonumber(cleared.city_rank))
    assert.are.equal("", cleared.current_form)
    assert.are.equal("", cleared.elemental_type)
  end)

  it("stores class specializations against the active class only", function()
    agnosticdb.db.upsert_person({ name = "Knight", class = "Runewarden", specialization = "2H" })
    agnosticdb.db.upsert_person({ name = "Knight", class = "Magi" })

    assert.are.equal("2H", agnosticdb.db.get_class_spec("Knight", "Runewarden"))
    assert.is_nil(agnosticdb.db.get_class_spec("Knight", "Magi"))
    assert.is_nil(agnosticdb.db.get_current_specialization("Knight"))
  end)
end)
