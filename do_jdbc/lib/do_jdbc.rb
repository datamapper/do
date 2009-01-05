if RUBY_PLATFORM =~ /java/
  require 'java'
  require 'bigdecimal'
  require 'do_jdbc_internal'
  require 'rubygems'
  gem 'data_objects'
  require 'data_objects'
  require 'do_jdbc/date_formatter'
  require 'do_jdbc/time_formatter'
  require 'do_jdbc/datetime_formatter'
else
  warn "do_jdbc is for use with JRuby only"
end
