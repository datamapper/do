require 'rubygems'
require 'spec'

dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
require 'data_objects'

require File.expand_path(File.join(File.dirname(__FILE__), 'do_mock'))
