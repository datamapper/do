if RUBY_PLATFORM =~ /java/
  require 'pathname'
  require 'sqlite3_version'
  require Pathname(__FILE__).dirname.expand_path.parent + "#{DataObjects::Jdbc::SQLite3::JAR_NAME}"
else
  warn "do_jdbc-SQLite3 is only for use with JRuby"
end
