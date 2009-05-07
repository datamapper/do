# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/datetime_spec'

describe 'DataObjects::Sqlite3 with DateTime' do
  it_should_behave_like 'supporting DateTime'
end
