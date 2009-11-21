# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/byte_array_spec'

describe 'DataObjects::Mysql with ByteArray' do
  behaves_like 'supporting ByteArray'
end
