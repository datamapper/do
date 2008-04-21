$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'data_objects', 'lib')

require 'rubygems'
require 'spec'
require 'data_objects'
require 'date'
require 'do_mysql'
