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
  IO.popen("pg_config --#{type}dir").readline.chomp rescue nil
end

def have_build_env
  (have_library('pq') || have_library('libpq')) &&
    have_header('libpq-fe.h') && have_header('libpq/libpq-fs.h')
end

dir_config('pgsql', config_value('include'), config_value('lib'))

required_libraries = []
desired_functions = %w(PQsetClientEncoding pg_encoding_to_char PQfreemem)
compat_functions = %w(PQescapeString PQexecParams)

if have_build_env
  required_libraries.each(&method(:have_library))
  desired_functions.each(&method(:have_func))
  $CFLAGS << ' -Wall ' unless RUBY_PLATFORM =~ /mswin/
  create_makefile("do_postgres_ext")
else
  puts 'Could not find PostgreSQL build environment (libraries & headers): Makefile not created'
  exit(1)
end
