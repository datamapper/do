require 'rubygems'
require 'data_objects'
require 'rspec'

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
