# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/byte_array_spec'

describe 'DataObjects::Hsqldb with ByteArray' do
  # We need to switch to using parameter binding for this to work with Hsqldb
  # it_should_behave_like 'supporting ByteArray'
end
