# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/connection_spec'

describe DataObjects::Openedge::Connection do

  before :all do
    @driver = CONFIG.scheme
    @user   = CONFIG.user
    @password = CONFIG.pass
    @host   = CONFIG.host
    @port   = CONFIG.port
    #TODO
    #@service = CONFIG.service
    @database = CONFIG.database
  end

  it_should_behave_like 'a Connection'
  #it_should_behave_like 'a Connection with authentication support'
  it_should_behave_like 'a Connection with JDBC URL support'
  #it_should_behave_like 'a Connection via JDNI'
end
