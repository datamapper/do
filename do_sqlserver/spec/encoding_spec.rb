# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/encoding_spec'

describe DataObjects::Sqlserver::Connection do
  it_should_behave_like 'a driver supporting encodings'
end
