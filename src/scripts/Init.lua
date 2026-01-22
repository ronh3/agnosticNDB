agnosticdb = agnosticdb or {}

agnosticdb.version = "@VERSION@"
agnosticdb.package = "@PKGNAME@"

function agnosticdb.init()
  if agnosticdb.config and agnosticdb.config.load then
    agnosticdb.config.load()
  end

  if agnosticdb.db and agnosticdb.db.init then
    agnosticdb.db.init()
  end
end

agnosticdb.init()
