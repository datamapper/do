require 'derby_version'

if RUBY_PLATFORM =~ /java/
  require "derby-#{DataObjects::Jdbc::Derby::VERSION}.jar"
else
  warn "do_jdbc-derby is only for use with JRuby"
end
