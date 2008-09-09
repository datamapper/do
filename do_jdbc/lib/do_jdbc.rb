if RUBY_PLATFORM =~ /java/
  require 'do_jdbc_internal'
else
  warn "do_jdbc is for use with JRuby only"
end
