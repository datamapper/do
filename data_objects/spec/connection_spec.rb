require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Connection do
  before do
    @connection = DataObjects::Connection.new('mock://localhost')
  end

  %w{dispose create_command}.each do |meth|
    it "should respond to ##{meth}" do
      @connection.should respond_to(meth.intern)
    end
  end

  it "should have #to_s that returns the connection uri string" do
    @connection.to_s.should == 'mock://localhost'
  end

  describe "getting inherited" do
    # HACK: Connections needs to exist under the DataObjects namespace?
    module DataObjects
      class MyConnection < DataObjects::Connection; end
    end

    it "should set the @connection_lock ivar to a Mutex" do
      DataObjects::MyConnection.instance_variable_get("@connection_lock").should_not be_nil
      DataObjects::MyConnection.instance_variable_get("@connection_lock").should be_kind_of(Mutex)
    end

    it "should set the @available_connections ivar to a Hash" do
      DataObjects::MyConnection.instance_variable_get("@available_connections").should_not be_nil
      DataObjects::MyConnection.instance_variable_get("@available_connections").should be_kind_of(Hash)
    end

    it "should set the @reserved_connections ivar to a Set" do
      DataObjects::MyConnection.instance_variable_get("@reserved_connections").should_not be_nil
      DataObjects::MyConnection.instance_variable_get("@reserved_connections").should be_kind_of(Set)
    end
  end

  describe "initialization" do
    it "should accept a regular connection uri as a String" do
      c = DataObjects::Connection.new('mock://localhost/database')
      # relying on the fact that mock connection sets @uri
      uri = c.instance_variable_get("@uri")

      uri.should be_kind_of(Addressable::URI)
      uri.scheme.should == 'mock'
      uri.host.should == 'localhost'
      uri.path.should == '/database'
    end

    it "should accept a connection uri as a Addressable::URI" do
      c = DataObjects::Connection.new(Addressable::URI::parse('mock://localhost/database'))
      # relying on the fact that mock connection sets @uri
      uri = c.instance_variable_get("@uri")

      uri.should be_kind_of(Addressable::URI)
      uri.to_s.should == 'mock://localhost/database'
    end

    it "should determine which DataObject adapter to use from the uri scheme" do
      DataObjects::Mock::Connection.should_receive(:__new)
      DataObjects::Connection.new('mock://localhost/database')
    end

    it "should determine which DataObject adapter to use from a JDBC URL scheme" do
      DataObjects::Mock::Connection.should_receive(:__new)
      DataObjects::Connection.new('jdbc:mock://localhost/database')
    end

    it "should acquire a connection" do
      uri = Addressable::URI.parse('mock://localhost/database')
      DataObjects::Mock::Connection.should_receive(:__new).with(uri)

      DataObjects::Connection.new(uri)
    end

    it "should return the Connection specified by the scheme" do
      c = DataObjects::Connection.new(Addressable::URI.parse('mock://localhost/database'))
      c.should be_kind_of(DataObjects::Mock::Connection)
    end
  end
end
