# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/array_range_spec'

describe 'DataObjects::Mysql with Array and Range' do
  it_should_behave_like 'a driver supporting Array and Range'
end
