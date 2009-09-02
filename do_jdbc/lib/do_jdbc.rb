if RUBY_PLATFORM =~ /java/
  require 'java'
  require 'bigdecimal'
  require 'do_jdbc_internal'
  require 'data_objects'
else
  warn "do_jdbc is for use with JRuby only"
end
