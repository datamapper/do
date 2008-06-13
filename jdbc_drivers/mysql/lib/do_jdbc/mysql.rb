require 'mysql_version'

if RUBY_PLATFORM =~ /java/
  require "mysql-connector-java-#{DataObjects::Jdbc::MySQL::VERSION}-bin.jar"
else
  warn "do_jdbc-mysql is only for use with JRuby"
end
