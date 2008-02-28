# ENV["RC_ARCHS"] = `uname -m`.chomp if `uname -sr` =~ /^Darwin/
# 
# require 'mkmf'
# 
# SWIG_WRAP = "sqlite3_api_wrap.c"
# 
# dir_config( "sqlite3", "/usr/local" )
# 
# if have_header( "sqlite3.h" ) && have_library( "sqlite3", "sqlite3_open" )
#   create_makefile( "sqlite3_c" )
# end

# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'do_sqlite3'

dir_config("sqlite3", "/usr")

$CFLAGS << ' -Wall '

# The destination
dir_config(extension_name)

# Do the work
# create_makefile(extension_name)
if have_header( "sqlite3.h" ) && have_library( "sqlite3", "sqlite3_open" )
  create_makefile(extension_name)
end