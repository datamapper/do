if RUBY_PLATFORM =~ /java/
  require 'do_jdbc_internal'
else
  warn "do_jdbc-support is for use with JRuby only"
end
