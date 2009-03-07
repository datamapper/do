# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/byte_array_spec'

describe 'DataObjects::Sqlite3 with ByteArray' do
  # We need to switch to using parameter binding for this to work with Sqlite3
  # it_should_behave_like 'supporting ByteArray'
end
