require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Reader" do

  it "should inherit from DataObjects::Reader" do
    pending
    #DataObjects::Jdbc::const_get('Reader').new.should be_kind_of(DataObjects::Reader)
  end

  it "should have close, should, values, fields methods" do

    pending "Needs mocks to work"

    #connection = DataObjects::Connection.new('mock://localhost')
    #command = connection.create_command("SELECT * FROM example")
    #reader = command.execute_reader
    reader = DataObjects::Jdbc::const_get('Reader').new

    reader.should respond_to(:close)
    reader.should respond_to(:next!)
    reader.should respond_to(:values)
    reader.should respond_to(:fields)
    reader.should_not respond_to(:not_a_reader_method)
  end

end
