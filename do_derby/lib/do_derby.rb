DERBY_VERSION = '10.4.1.3'

if RUBY_PLATFORM =~ /java/
  require 'java'
  require "derby-#{DERBY_VERSION}.jar"
else
  warn "jdbc-derby is only for use with JRuby"
end
