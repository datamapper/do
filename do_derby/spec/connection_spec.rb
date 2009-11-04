# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'

describe DataObjects::Derby::Connection do

  before :all do
    @driver = 'derby'
    @user   = ''
    @password = ''
    @host   = ''
    @port   = ''
    @database = "#{File.expand_path(File.dirname(__FILE__))}/test.db;create=true"
  end

  it_should_behave_like 'a Connection'
  #it_should_behave_like 'a Connection with authentication support'
  it_should_behave_like 'a Connection via JDNI' if JRUBY
end
