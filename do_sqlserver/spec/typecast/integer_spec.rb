# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/integer_spec'

describe 'DataObjects::SqlServer with Integer' do
  behaves_like 'supporting Integer'
end
