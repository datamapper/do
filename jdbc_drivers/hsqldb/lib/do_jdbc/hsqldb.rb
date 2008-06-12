module DataObjects
  module Jdbc
    module HSQLDB
      VERSION = "1.8.0.7"
    end
  end
end

if RUBY_PLATFORM =~ /java/
  require "hsqldb-#{DataObjects::Jdbc::HSQLDB::VERSION}.jar"
else
  warn "jdbc-hsqldb is only for use with JRuby"
end
