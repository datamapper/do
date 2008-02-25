$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'data_objects', 'lib')

require 'data_objects'
require 'do_mysql'