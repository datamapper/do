$TESTING=true

require 'rubygems'
require 'spec'
require 'date'
# push data_objects from repository in the load path
# DO NOT USE installed gem of data_objects!
$:.push File.join(File.dirname(__FILE__), '../../data_objects', 'lib')
require 'data_objects'

# put the pre-compiled extension in the path to be found
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'do_mysql'
