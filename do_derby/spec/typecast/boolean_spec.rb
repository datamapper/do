# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/boolean_spec'

describe 'DataObjects::Derby with Boolean' do
  behaves_like 'supporting Boolean'
  # TODO should we map smallint to boolean for derby ??
#  behaves_like 'supporting Boolean autocasting'
end
