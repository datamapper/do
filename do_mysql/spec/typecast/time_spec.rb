# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/time_spec'

describe 'DataObjects::Mysql with Time' do
  it_should_behave_like 'supporting Time'
end
