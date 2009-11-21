# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/datetime_spec'

describe 'DataObjects::SqlServer with DateTime' do
  behaves_like 'supporting DateTime'
  # behaves_like 'supporting DateTime autocasting'
end
