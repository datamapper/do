ENV["RC_ARCHS"] = `uname -m`.chomp if `uname -sr` =~ /^Darwin/

require 'mkmf'

SWIG_WRAP = "sqlite3_api_wrap.c"

dir_config( "sqlite3", "/usr/local" )

if have_header( "sqlite3.h" ) && have_library( "sqlite3", "sqlite3_open" )
  create_makefile( "sqlite3_c" )
end
