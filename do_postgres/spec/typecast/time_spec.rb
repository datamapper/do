# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/time_spec'

describe 'DataObjects::Postgres with Time' do
  it_should_behave_like 'supporting Time'
  it_should_behave_like 'supporting sub second Time'
end
