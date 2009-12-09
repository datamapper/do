require 'rubygems'
require 'bacon'
require 'facon'

dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
require 'data_objects'
require 'lib/immediate_red_green_output'

module DataObjects::Pooling
  class << self
    remove_method :scavenger_interval if instance_methods(false).any? { |m| m.to_sym == :scavenger_interval }
    def scavenger_interval
      0.5
    end
  end
end

require File.expand_path(File.join(File.dirname(__FILE__), 'do_mock'))
require File.expand_path(File.join(File.dirname(__FILE__), 'do_mock2'))

Bacon.extend Bacon::ImmediateRedGreenOutput
Bacon.summary_on_exit
