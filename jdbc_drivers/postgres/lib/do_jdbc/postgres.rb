require 'postgres_version'

if RUBY_PLATFORM =~ /java/
  require "postgresql-#{DataObjects::Jdbc::Postgres::VERSION}-504.jdbc3.jar"
else
  warn "do_jdbc-postgres is only for use with JRuby"
end
