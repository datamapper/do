# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/connection_spec'

describe DataObjects::Sqlite3::Connection do

  before :all do
    @driver = CONFIG.scheme
    @user   = CONFIG.user
    @password = CONFIG.pass
    @host   = CONFIG.host
    @port   = CONFIG.port
    @database = CONFIG.database
  end

  it_should_behave_like 'a Connection'
  it_should_behave_like 'a Connection via JDNI' if JRUBY
  it_should_behave_like 'a Connection with JDBC URL support' if JRUBY

  unless JRUBY

    describe 'connecting with busy timeout' do

      it 'connects with a valid timeout' do
        DataObjects::Connection.new("#{CONFIG.uri}?busy_timeout=200").should_not be_nil
      end

      it 'raises an error when passed an invalid value' do
        lambda { DataObjects::Connection.new("#{CONFIG.uri}?busy_timeout=stuff") }.
          should raise_error(ArgumentError)
      end

    end
  end

end
