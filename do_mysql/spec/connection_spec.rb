# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'
require 'cgi'

describe DataObjects::Mysql::Connection do

  before :all do
    @driver = CONFIG.scheme
    @user   = CONFIG.user
    @password = CONFIG.pass
    @host   = CONFIG.host
    @port   = CONFIG.port
    @database = CONFIG.database
    @ssl    = CONFIG.ssl
  end

  it_should_behave_like 'a Connection'
  #it_should_behave_like 'a Connection with authentication support'
  it_should_behave_like 'a Connection with SSL support'

  if DataObjectsSpecHelpers.test_environment_supports_ssl?

    describe 'connecting with SSL' do

      it 'should connect with a specified SSL cipher' do
        DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}&ssl[cipher]=#{SSLHelpers::CONFIG.cipher}").
          ssl_cipher.should == SSLHelpers::CONFIG.cipher
      end
      
      it 'should raise an error with an invalid SSL cipher' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?#{CONFIG.ssl}&ssl[cipher]=invalid") }.
          should raise_error
      end
    end
    
  end

end
