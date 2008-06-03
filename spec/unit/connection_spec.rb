require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Connection" do

  it "should have initialize, real_close methods" do
    connection = DataObjects::Jdbc::const_get('Connection').new("jdbc://test/")

    connection.should respond_to(:initialize)
    connection.should respond_to(:real_close)
    connection.should_not respond_to(:not_a_conn_method)
  end

end
