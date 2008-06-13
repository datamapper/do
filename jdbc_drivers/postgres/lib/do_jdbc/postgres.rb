if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require Pathname(__FILE__).dirname.expand_path + 'postgres_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::Postgres::JAR_NAME}"
else
  warn "do_jdbc-postgres is only for use with JRuby"
end
