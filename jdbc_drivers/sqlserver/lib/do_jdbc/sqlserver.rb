if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require Pathname(__FILE__).dirname.expand_path + 'sqlserver_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::SqlServer::JAR_NAME}"
else
  warn "do_jdbc-sqlserver is only for use with JRuby"
end
