# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'

describe DataObjects::Postgres::Connection do

  before :all do
    @driver = CONFIG.scheme
    @user   = CONFIG.user
    @password = CONFIG.pass
    @host   = CONFIG.host
    @port   = CONFIG.port
    @database = CONFIG.database
  end

  it_should_behave_like 'a Connection'
  it_should_behave_like 'a Connection with authentication support'

  describe "byte array quoting" do
    it "should properly escape non-printable ASCII characters" do
      @connection.quote_byte_array("\001").should match(/'\\?\\001'/)
    end

    it "should properly escape bytes with the high bit set" do
      @connection.quote_byte_array("\210").should match(/'\\?\\210'/)
    end

    it "should not escape printable ASCII characters" do
      @connection.quote_byte_array("a").should eql("'a'")
    end
  end
end
