if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require Pathname(__FILE__).dirname.expand_path + 'derby_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::Derby::JAR_NAME}"
else
  warn "do_jdbc-derby is only for use with JRuby"
end
