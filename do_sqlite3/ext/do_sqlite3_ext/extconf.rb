ENV["RC_ARCHS"] = "" if RUBY_PLATFORM =~ /darwin/

# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'do_sqlite3_ext'

# Use some default search paths
dir_config("sqlite3", ["/usr/local", "/opt/local", "/usr"])

# NOTE: use GCC flags unless Visual C compiler is used
$CFLAGS << ' -Wall ' unless RUBY_PLATFORM =~ /mswin/

if RUBY_VERSION < '1.8.6'
  $CFLAGS << ' -DRUBY_LESS_THAN_186'
end

# Do the work
# create_makefile(extension_name)
if have_header( "sqlite3.h" ) && have_library( "sqlite3", "sqlite3_open" )
  have_func("sqlite3_prepare_v2")
  have_func("sqlite3_open_v2")

  create_makefile(extension_name)
end
