if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require Pathname(__FILE__).dirname.expand_path + 'hsqldb_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::HSQLDB::JAR_NAME}"
else
  warn "do_jdbc-hsqldb is only for use with JRuby"
end
