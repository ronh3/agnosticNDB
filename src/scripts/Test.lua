agnosticdb = agnosticdb or {}

agnosticdb.test = agnosticdb.test or {}

local function prefix()
  if agnosticdb.ui and agnosticdb.ui.theme_tags then
    local theme = agnosticdb.ui.theme_tags()
    if theme and theme.accent and theme.text then
      return string.format("%s[agnosticdb test]%s %s", theme.accent, theme.reset or "<reset>", theme.text)
    end
  end
  return "<cyan>[agnosticdb test]<reset> "
end

local function needs_leading_newline()
  if type(line) ~= "string" or line == "" then return false end
  if agnosticdb._echo_line_pending then return false end
  agnosticdb._echo_line_pending = true
  if type(tempTimer) == "function" then
    tempTimer(0, function() agnosticdb._echo_line_pending = false end)
  else
    agnosticdb._echo_line_pending = false
  end
  return true
end

local function echo_line(text)
  local lead = needs_leading_newline() and "\n" or ""
  local reset = "<reset>"
  if agnosticdb.ui and agnosticdb.ui.theme_tags then
    local theme = agnosticdb.ui.theme_tags()
    if theme and theme.reset then
      reset = theme.reset
    end
  end
  cecho(lead .. prefix() .. text .. reset .. "\n")
end

local function pass(msg)
  echo_line("PASS: " .. msg)
end

local function fail(msg)
  echo_line("FAIL: " .. msg)
end

local function warn(msg)
  echo_line("WARN: " .. msg)
end

function agnosticdb.test.run()
  echo_line("Running agnosticDB self-test...")

  if agnosticdb.db and agnosticdb.db.init then
    agnosticdb.db.init()
  end

  local test_name = "Testperson"
  agnosticdb.db.upsert_person({ name = test_name, class = "magi", city = "Ashtan", notes = "hello" })
  local person = agnosticdb.db.get_person(test_name)
  if person and person.name == "Testperson" and person.class == "magi" then
    pass("DB upsert/get person")
  else
    fail("DB upsert/get person")
  end

  agnosticdb.notes.set("NotePerson", "note text")
  local note = agnosticdb.notes.get("NotePerson")
  if note == "note text" then
    pass("Notes set/get")
  else
    fail("Notes set/get")
  end

  agnosticdb.politics.set_city_relation("Ashtan", "enemy")
  agnosticdb.db.upsert_person({ name = "EnemyCandidate", city = "Ashtan", iff = "auto" })
  if agnosticdb.iff.is_enemy("EnemyCandidate") then
    pass("Politics + IFF derived enemy")
  else
    fail("Politics + IFF derived enemy")
  end

  agnosticdb.iff.set("EnemyCandidate", "ally")
  if not agnosticdb.iff.is_enemy("EnemyCandidate") then
    pass("IFF ally override")
  else
    fail("IFF ally override")
  end

  agnosticdb.highlights.ignore("IgnoreMe")
  if agnosticdb.highlights.is_ignored("IgnoreMe") then
    pass("Highlight ignore")
  else
    fail("Highlight ignore")
  end

  agnosticdb.highlights.unignore("IgnoreMe")
  if not agnosticdb.highlights.is_ignored("IgnoreMe") then
    pass("Highlight unignore")
  else
    fail("Highlight unignore")
  end

  if type(getHTTP) ~= "function" then
    warn("getHTTP not available; skipping API list fetch")
    echo_line("Self-test complete.")
    return
  end

  agnosticdb.api.fetch_list(function(names, status)
    if status ~= "ok" or type(names) ~= "table" then
      warn("API list fetch failed: " .. tostring(status))
      echo_line("Self-test complete.")
      return
    end

    local count = agnosticdb.api.seed_names(names, "api_list")
    pass(string.format("API list fetched (%d names, %d added)", #names, count))
    echo_line("Self-test complete.")
  end)
end
