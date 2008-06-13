if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require 'mysql_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::MySQL::JAR_NAME}"
else
  warn "do_jdbc-mysql is only for use with JRuby"
end
