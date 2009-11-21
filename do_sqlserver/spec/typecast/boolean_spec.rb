# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/boolean_spec'

describe 'DataObjects::SqlServer with Boolean' do
  behaves_like 'supporting Boolean'
  behaves_like 'supporting Boolean autocasting'
end
