require 'rubygems'
require 'data_objects'

DERBY_VERSION = '10.4.1.3'

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc-support'
  require 'do_derby-ext-java'
  require 'java'
  require "derby-#{DERBY_VERSION}.jar"
else
  warn "do-derby is only for use with JRuby"
end
