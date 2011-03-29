# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/reader_spec'

describe DataObjects::Postgres::Reader do
  it_should_behave_like 'a Reader'
end
