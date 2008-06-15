require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Command" do

  it "should inherit from DataObjects::Command" do
    pending
    #DataObjects::Jdbc::const_get('Command').new.should be_kind_of(DataObjects::Command)
  end

  it "should have set_types, execute_non_query, execute_reader and quote_string methods" do
    pending
    #connection = mock()
    #DataObjects::Jdbc::Connection.expects(:new).with("jdbc://mock/mock").times(2)
    #command = DataObjects::Jdbc::const_get('Command').new(connection, 'SQL String')

   # connection.expects(:connection).times(3)
    command.should respond_to(:set_types)
    command.should respond_to(:execute_non_query)
    command.should respond_to(:execute_reader)
    command.should respond_to(:quote_string)
    command.should_not respond_to(:not_a_command_method)
  end

  it "should quote string" do
    pending
    #command = DataObjects::Jdbc::Command.new(connection=mock, 'SQL String')
  end

end
