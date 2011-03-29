# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/float_spec'

describe 'DataObjects::Sqlite3 with Float' do
  it_should_behave_like 'supporting Float'
end

describe 'DataObjects::Sqlite3 with Float' do
  it_should_behave_like 'supporting Float autocasting'
end
