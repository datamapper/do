ENV["RC_ARCHS"] = "" if RUBY_PLATFORM =~ /darwin/

require 'mkmf'
require 'date'

# Allow for custom compiler to be specified.
RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

def config_value(type)
  ENV["POSTGRES_#{type.upcase}"] || pg_config(type)
end

def pg_config(type)
  IO.popen("pg_config --#{type}").readline.chomp rescue nil
end

def have_build_env
  (have_library('pq') || have_library('libpq')) &&
  have_header('libpq-fe.h') && have_header('libpq/libpq-fs.h') &&
  have_header('postgres.h') && have_header('mb/pg_wchar.h') &&
  have_header('catalog/pg_type.h')
end

$CFLAGS << ' -UENABLE_NLS -DHAVE_GETTIMEOFDAY -DHAVE_CRYPT' if RUBY_PLATFORM =~ /mswin|mingw/

unless DateTime.respond_to?(:new!)
  $CFLAGS << ' -DHAVE_NO_DATETIME_NEWBANG'
end

dir_config('pgsql-server', config_value('includedir-server'), config_value('libdir'))
dir_config('pgsql-client', config_value('includedir'), config_value('libdir'))
dir_config('pgsql-win32') if RUBY_PLATFORM =~ /mswin|mingw/

desired_functions = %w(localtime_r gmtime_r PQsetClientEncoding pg_encoding_to_char PQfreemem)
compat_functions = %w(PQescapeString PQexecParams)

if have_build_env
  desired_functions.each(&method(:have_func))
  $CFLAGS << ' -Wall ' unless RUBY_PLATFORM =~ /mswin/
  if RUBY_VERSION < '1.8.6'
    $CFLAGS << ' -DRUBY_LESS_THAN_186'
  end

  create_makefile("do_postgres/do_postgres")
else
  puts 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
  exit(1)
end
