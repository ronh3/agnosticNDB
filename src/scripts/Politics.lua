agnosticdb = agnosticdb or {}

agnosticdb.politics = agnosticdb.politics or {}

function agnosticdb.politics.set_city_relation(city, relation)
  agnosticdb.conf = agnosticdb.conf or {}
  agnosticdb.conf.politics = agnosticdb.conf.politics or {}
  agnosticdb.conf.politics[city] = relation
  agnosticdb.config.save()
end

function agnosticdb.politics.get_city_relation(city)
  agnosticdb.conf = agnosticdb.conf or {}
  local politics = agnosticdb.conf.politics or {}
  return politics[city]
end
