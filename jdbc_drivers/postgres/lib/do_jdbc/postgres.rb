module DataObjects
  module Jdbc
    module Postgres
      VERSION = "8.2"
    end
  end
end

if RUBY_PLATFORM =~ /java/
  require "postgresql-#{DataObjects::Jdbc::Postgres::VERSION}-504.jdbc3.jar"
else
  warn "jdbc-postgres is only for use with JRuby"
end
