# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/boolean_spec'

describe 'DataObjects::Postgres with Boolean' do
  it_should_behave_like 'supporting Boolean'
  it_should_behave_like 'supporting Boolean autocasting'
end
