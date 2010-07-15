# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/error/sql_error_spec'

describe 'DataObjects::Mysql raising SQLError' do
  behaves_like 'raising a SQLError'
end
