local helper = dofile(os.getenv("TESTS_DIRECTORY") .. "/support/agnosticdb_test_helper.lua")

describe("agnosticdb api", function()
  local saved_getHTTP
  local saved_time

  before_each(function()
    helper.reset()
    saved_getHTTP = _G.getHTTP
    saved_time = os.time
  end)

  after_each(function()
    _G.getHTTP = saved_getHTTP
    os.time = saved_time
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

  it("estimates queue time from queue length, pacing, and backoff", function()
    os.time = function()
      return 100
    end

    agnosticdb.conf.api.min_interval_seconds = 3
    agnosticdb.api.queue = { "One", "Two" }
    agnosticdb.api.last_request_time = 98
    agnosticdb.api.backoff_until = 105
    agnosticdb.api.queue_stats = {
      processed = 2,
      started_at = 92,
    }

    assert.are.equal(18, agnosticdb.api.estimate_queue_seconds(1))
  end)

  it("cancels the pending queue and clears queue state", function()
    agnosticdb.api.queue = { "One", "Two", "Three" }
    agnosticdb.api.queued = { One = true, Two = true, Three = true }
    agnosticdb.api.queue_running = true
    agnosticdb.api.queue_stats = { total = 3 }
    agnosticdb.api.on_queue_done = function() end

    local pending = agnosticdb.api.cancel_queue()

    assert.are.equal(3, pending)
    assert.are.same({}, agnosticdb.api.queue)
    assert.are.same({}, agnosticdb.api.queued)
    assert.is_false(agnosticdb.api.queue_running)
    assert.is_nil(agnosticdb.api.queue_stats)
    assert.is_nil(agnosticdb.api.on_queue_done)
  end)

  it("fetches only missing online names with fetch_online_new", function()
    agnosticdb.db.upsert_person({ name = "Knownone", city = "Ashtan" })

    local fetch_list_stub = stub(agnosticdb.api, "fetch_list", function(on_done)
      on_done({ "Knownone", "Newone", "Newtwo" }, "ok")
    end)
    local queue_stub = stub(agnosticdb.api, "queue_fetches", function(names, opts)
      assert.are.same({ "Newone", "Newtwo" }, names)
      assert.are.same({ force = true }, opts)
      return 2
    end)

    local payload, status = nil, nil
    agnosticdb.api.fetch_online_new(function(result, result_status)
      payload = result
      status = result_status
    end)

    fetch_list_stub:revert()
    queue_stub:revert()

    assert.are.equal("ok", status)
    assert.are.same({ "Knownone", "Newone", "Newtwo" }, payload.names)
    assert.are.same({ "Newone", "Newtwo" }, payload.missing)
    assert.are.equal(2, payload.added)
    assert.are.equal(2, payload.queued)
    assert.are.equal("api_list", agnosticdb.db.get_person("Newone").source)
    assert.are.equal("api_list", agnosticdb.db.get_person("Newtwo").source)
  end)
end)
