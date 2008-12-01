require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Hsqldb::Connection" do

  it "should inherit from DataObjects::Connection" do
    #@connection = mock
    #DataObjects::Connection.expects(:new).with("jdbc://mock/mock").times(2)
    #@connection = DataObjects::Jdbc::Connection.new("jdbc://mock/mock")

    pending
    #DataObjects::Jdbc::const_get('Connection').new.should be_kind_of(DataObjects::Connection)
  end

  it "should have initialize, real_close methods" do

    pending "Needs mocks to work"

    connection = DataObjects::Hsqldb::const_get('Connection').new("jdbc://test/")

    connection.should respond_to(:initialize)
    connection.should respond_to(:real_close)
    connection.should_not respond_to(:not_a_conn_method)
  end

end
