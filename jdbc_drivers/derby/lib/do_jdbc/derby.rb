module DataObjects
  module Jdbc
    module Derby
      VERSION = '10.4.1.3'
    end
  end
end

if RUBY_PLATFORM =~ /java/
  require "derby-#{DataObjects::Jdbc::Derby::VERSION}.jar"
else
  warn "jdbc-derby is only for use with JRuby"
end
