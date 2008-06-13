if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require 'h2_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::H2::JAR_NAME}"
else
  warn "do_jdbc-h2 is only for use with JRuby"
end
