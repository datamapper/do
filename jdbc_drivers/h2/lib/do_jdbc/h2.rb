require 'h2_version'

if RUBY_PLATFORM =~ /java/
  require "h2-#{DataObjects::Jdbc::H2::VERSION}.jar"
else
  warn "do_jdbc-h2 is only for use with JRuby"
end
