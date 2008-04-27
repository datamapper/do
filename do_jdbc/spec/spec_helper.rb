$TESTING=true

require 'rubygems'
require 'spec'
require 'date'

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'data_objects', 'lib')

require 'data_objects'
