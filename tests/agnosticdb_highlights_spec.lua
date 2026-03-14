local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb highlights", function()
  local saved_tempRegexTrigger
  local saved_killTrigger

  before_each(function()
    helper.reset()
    saved_tempRegexTrigger = _G.tempRegexTrigger
    saved_killTrigger = _G.killTrigger
  end)

  after_each(function()
    _G.tempRegexTrigger = saved_tempRegexTrigger
    _G.killTrigger = saved_killTrigger
  end)

  it("uses apostrophe-aware boundaries for generated highlight triggers", function()
    local seen_pattern

    _G.tempRegexTrigger = function(pattern, fn)
      seen_pattern = pattern
      return 101
    end
    _G.killTrigger = function() end

    agnosticdb.conf.highlights_enabled = true
    agnosticdb.conf.highlight = {
      enemies = {},
      cities = {
        ashtan = { color = "red" },
      },
    }

    agnosticdb.db.upsert_person({ name = "Aren", city = "Ashtan" })
    agnosticdb.highlights.reload()

    assert.are.equal("(?<![A-Za-z'])Aren(?![A-Za-z'])", seen_pattern)
    assert.are.equal(101, agnosticdb.highlights.ids.Aren)
  end)
end)
