# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/array_spec'

describe 'DataObjects::Postgres with Array' do
  it_should_behave_like 'supporting Array'
end
