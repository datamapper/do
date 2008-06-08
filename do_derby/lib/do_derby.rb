require 'rubygems'
require 'data_objects'

module DataObjects
  module Derby
    JDBC_DRIVER_VERSION = '10.4.1.3'
  end
end

if RUBY_PLATFORM =~ /java/
  require 'do_jdbc-support'
  require 'do_derby_ext'
  require 'java'
  require "derby-#{DataObjects::Derby::JDBC_DRIVER_VERSION}.jar"
else
  warn "do-derby is only for use with JRuby"
end
