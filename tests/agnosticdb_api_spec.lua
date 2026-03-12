local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb api", function()
  local saved_getHTTP

  before_each(function()
    helper.reset()
    saved_getHTTP = _G.getHTTP
  end)

  after_each(function()
    _G.getHTTP = saved_getHTTP
  end)

  it("parses the online character list", function()
    _G.getHTTP = function(url)
      assert.are.equal("https://api.achaea.com/characters.json", url)
      return '{"characters":["Testone","Testtwo"]}', 200
    end

    local names, status
    agnosticdb.api.fetch_list(function(result, result_status)
      names = result
      status = result_status
    end)

    assert.are.equal("ok", status)
    assert.are.same({"Testone", "Testtwo"}, names)
  end)

  it("fetches and stores a character record from the API", function()
    local http_calls = 0
    _G.getHTTP = function(url)
      http_calls = http_calls + 1
      assert.are.equal("https://api.achaea.com/characters/Testperson.json", url)
      return [[{"name":"Testperson","fullname":"Testperson, Example","city":"ashtan","class":"magi","house":"scions","xp_rank":123,"level":99}]], 200
    end

    local person, status
    agnosticdb.api.fetch("Testperson", function(result, result_status)
      person = result
      status = result_status
    end, { force = true })

    assert.are.equal(1, http_calls)
    assert.are.equal("ok", status)
    assert.are.equal("Testperson", person.name)
    assert.are.equal("Magi", person.class)
    assert.are.equal("Ashtan", person.city)
    assert.are.equal("Scions", person.house)
    assert.are.equal(123, tonumber(person.xp_rank))
    assert.are.equal(99, tonumber(person.level))
  end)

  it("returns cached records without making an HTTP request", function()
    agnosticdb.db.upsert_person({
      name = "Cachedperson",
      class = "Magi",
      city = "Ashtan",
      last_checked = os.time(),
    })

    local http_calls = 0
    _G.getHTTP = function()
      http_calls = http_calls + 1
      return nil, "should_not_be_called"
    end

    local person, status
    agnosticdb.api.fetch("Cachedperson", function(result, result_status)
      person = result
      status = result_status
    end)

    assert.are.equal(0, http_calls)
    assert.are.equal("cached", status)
    assert.are.equal("Cachedperson", person.name)
  end)
end)
