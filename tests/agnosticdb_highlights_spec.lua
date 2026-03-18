local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb highlights", function()
  local saved_tempRegexTrigger
  local saved_killTrigger
  local saved_selectString
  local saved_selectSection
  local saved_fg
  local saved_setBold
  local saved_setUnderline
  local saved_setItalics
  local saved_deselect
  local saved_resetFormat
  local saved_line

  before_each(function()
    helper.reset()
    saved_tempRegexTrigger = _G.tempRegexTrigger
    saved_killTrigger = _G.killTrigger
    saved_selectString = _G.selectString
    saved_selectSection = _G.selectSection
    saved_fg = _G.fg
    saved_setBold = _G.setBold
    saved_setUnderline = _G.setUnderline
    saved_setItalics = _G.setItalics
    saved_deselect = _G.deselect
    saved_resetFormat = _G.resetFormat
    saved_line = _G.line
  end)

  after_each(function()
    _G.tempRegexTrigger = saved_tempRegexTrigger
    _G.killTrigger = saved_killTrigger
    _G.selectString = saved_selectString
    _G.selectSection = saved_selectSection
    _G.fg = saved_fg
    _G.setBold = saved_setBold
    _G.setUnderline = saved_setUnderline
    _G.setItalics = saved_setItalics
    _G.deselect = saved_deselect
    _G.resetFormat = saved_resetFormat
    _G.line = saved_line
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

  it("styles matched names by occurrence instead of selectSection offsets", function()
    local trigger_fn
    local selected = {}
    local style_calls = {}

    _G.tempRegexTrigger = function(_, fn)
      trigger_fn = fn
      return 202
    end
    _G.killTrigger = function() end
    _G.selectString = function(name, occurrence)
      table.insert(selected, { name = name, occurrence = occurrence })
      return 1
    end
    _G.selectSection = function()
      error("selectSection should not be used when selectString is available")
    end
    _G.fg = function(color)
      table.insert(style_calls, { "fg", color })
    end
    _G.setBold = function(value)
      table.insert(style_calls, { "bold", value })
    end
    _G.setUnderline = function(value)
      table.insert(style_calls, { "underline", value })
    end
    _G.setItalics = function(value)
      table.insert(style_calls, { "italics", value })
    end
    _G.deselect = function()
      table.insert(style_calls, { "deselect" })
    end
    _G.resetFormat = function()
      table.insert(style_calls, { "reset" })
    end

    agnosticdb.conf.highlights_enabled = true
    agnosticdb.conf.highlight = {
      enemies = {},
      cities = {
        ashtan = { color = "purple", bold = true },
      },
    }

    agnosticdb.db.upsert_person({ name = "Seirshya", city = "Ashtan" })
    agnosticdb.highlights.reload()

    _G.line = "A runic totem is planted solidly in the ground. Seirshya, of Ashtan is here."
    trigger_fn()

    assert.are.same({ { name = "Seirshya", occurrence = 1 } }, selected)
    assert.are.same({
      { "fg", "purple" },
      { "bold", true },
      { "deselect" },
      { "reset" },
    }, style_calls)
  end)
end)
