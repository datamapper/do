# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/other_spec'

describe 'DataObjects::H2 with other (unknown) type' do
  it_should_behave_like 'supporting other (unknown) type'
end
