require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Connection do
  before do
    @connection = DataObjects::Connection.new('mock://localhost')
  end

  after do
    @connection.release
  end

  %w{dispose create_command}.each do |meth|
    it "should respond to ##{meth}" do
      @connection.should respond_to(meth.intern)
    end
  end

  it "should have #to_s that returns the connection uri string" do
    @connection.to_s.should == 'mock://localhost'
  end

  describe "initialization" do

    it "should accept a connection uri as a Addressable::URI" do
      c = DataObjects::Connection.new(Addressable::URI::parse('mock://localhost/database'))
      # relying on the fact that mock connection sets @uri
      c.to_s.should == 'mock://localhost/database'
    end

    it "should return the Connection specified by the scheme" do
      c = DataObjects::Connection.new(Addressable::URI.parse('mock://localhost/database'))
      c.should be_kind_of(DataObjects::Mock::Connection)

      c = DataObjects::Connection.new(Addressable::URI.parse('mock:jndi://jdbc/database'))
      c.should be_kind_of(DataObjects::Mock::Connection)
    end

    it "should set max_size as given in query part of URI" do
      c = DataObjects::Connection.new(Addressable::URI.parse('mock://localhost/database?pool_max_size=2'))
      c.instance_variable_get(:@__pool).instance_variable_get(:@max_size).should == 2
    end

    it "should have a NoPool if max_size == 0" do
      c = DataObjects::Connection.new(Addressable::URI.parse('mock://localhost/database2?pool_max_size=0'))
      c.instance_variable_get(:@__pool).should be_nil

      cc = DataObjects::Connection.new(Addressable::URI.parse('mock://localhost/database2?pool_max_size=0'))
      c.object_id.should_not == cc.object_id
    end

    it "should have a NoPool for JNDI URIs" do
      c = DataObjects::Connection.new(Addressable::URI.parse('java://jdbc/database?scheme=mock'))
      c.instance_variable_get(:@__pool).should be_nil
    end

    it "should have a Pool for JNDI URIs when max_size is given" do
      c = DataObjects::Connection.new(Addressable::URI.parse('java://jdbc/database3?scheme=mock&pool_max_size=5'))
      c.instance_variable_get(:@__pool).should_not be_nil
    end
  end
end
