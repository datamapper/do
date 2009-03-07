# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'

describe DataObjects::Postgres::Connection do

  before :all do
    @driver = 'postgres'
    @user   = 'postgres'
    @password = ''
    @host   = 'localhost'
    @port   = '5432'
    @database = 'do_test'
  end

  it_should_behave_like 'a Connection'
  it_should_behave_like 'a Connection with authentication support'
end
