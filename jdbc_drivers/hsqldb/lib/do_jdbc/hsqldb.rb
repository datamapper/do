require 'hsqldb_version'

if RUBY_PLATFORM =~ /java/
  require "hsqldb-#{DataObjects::Jdbc::HSQLDB::VERSION}.jar"
else
  warn "do_jdbc-hsqldb is only for use with JRuby"
end
