require 'sqlite3_version'

if RUBY_PLATFORM =~ /java/
  require "sqlite-#{DataObjects::Jdbc::SQLite3::VERSION}.jar"
else
  warn "do_jdbc-SQLite3 is only for use with JRuby"
end
