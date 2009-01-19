if RUBY_PLATFORM =~ /darwin/
  ENV["RC_ARCHS"] = `uname -m`.chomp if `uname -sr` =~ /^Darwin/

  # On PowerPC the defaults are fine
  ENV["RC_ARCHS"] = '' if `uname -m` =~ /^Power Macintosh/
end

require 'mkmf'

# be polite: you can't force existance of uname functionality on all
# platforms.
if RUBY_PLATFORM =~ /darwin/
  ENV["RC_ARCHS"] = `uname -m`.chomp if `uname -sr` =~ /^Darwin/
end

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

dir_config('pgsql-server', config_value('includedir-server'), config_value('libdir'))
dir_config('pgsql-client', config_value('includedir'), config_value('libdir'))

required_libraries = []
desired_functions = %w(PQsetClientEncoding pg_encoding_to_char PQfreemem)
compat_functions = %w(PQescapeString PQexecParams)

if have_build_env
  required_libraries.each(&method(:have_library))
  desired_functions.each(&method(:have_func))
  $CFLAGS << ' -Wall ' unless RUBY_PLATFORM =~ /mswin/

  if RUBY_VERSION < '1.8.6'
    $CFLAGS << ' -DRUBY_LESS_THAN_186'
  end

  create_makefile("do_postgres_ext")
else
  puts 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
  exit(1)
end
