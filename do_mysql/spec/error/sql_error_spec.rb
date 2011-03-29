# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/error/sql_error_spec'

describe 'DataObjects::Mysql raising SQLError' do
  it_should_behave_like 'raising a SQLError'
end
