if `uname -sr` =~ /^Darwin/
  ENV["RC_ARCHS"] = `uname -m`.chomp
  unless File.exists?("/usr/local/mysql/lib/mysql")
    `sudo ln -s /usr/local/mysql/lib /usr/local/mysql/lib/mysql` rescue nil
  end
end

# Figure out where mysql_config is
if !`which mysql_config`.chomp.empty?
  @mysql_config_bin = "mysql_config"
elsif !`which mysql_config5`.chomp.empty?
  @mysql_config_bin = "mysql_config5"  
else
  puts "Cannot find mysql_config in your path. Please enter a location: "
  location = gets.chomp
  if File.exists?(location)
    @mysql_config_bin = location
  else
    puts "Cannot find that file. Exiting."
    exit
  end
end

require 'mkmf'
require 'open3'

def config_value(type)
  ENV["MYSQL_#{type.upcase}"] || mysql_config(type)
end

@mysql_config = {}

def mysql_config(type)
  return @mysql_config[type] if @mysql_config[type]

  sin, sout, serr = Open3.popen3("#{@mysql_config_bin} --#{type}")
  
  unless serr.read.empty?
    raise "mysql_config not found"
  end
  
  @mysql_config[type] = sout.readline.chomp[2..-1]
  @mysql_config[type]  
end

$inc, $lib = dir_config('mysql', config_value('include'), config_value('libs_r')) 

def have_build_env
  libs = ['m', 'z', 'socket', 'nsl']
  while not find_library('mysqlclient', "mysql_query", config_value('libs'), $lib, "#{$lib}/mysql") do
    exit 1 if libs.empty?
    have_library(libs.shift)
  end
  true
  # have_header('mysql.h')
end

required_libraries = [] #%w(m z socket nsl)
desired_functions = %w(mysql_ssl_set)
# compat_functions = %w(PQescapeString PQexecParams)

if have_build_env
  $CFLAGS << ' -Wall '
  dir_config("mysql_c")
  create_makefile("mysql_c")
else
  puts 'Could not find MySQL build environment (libraries & headers): Makefile not created'
end