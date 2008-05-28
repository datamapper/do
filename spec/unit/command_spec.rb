require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Command" do
  
  it "should have set_types, execute_non_query, execute_reader and quote_string methods" do
    command = DataObjects::Jdbc::const_get('Command').new(Object, Object)
                                                        # TODO: replace with mocks
    command.should respond_to(:set_types)
    command.should respond_to(:execute_non_query)
    command.should respond_to(:execute_reader)
    command.should respond_to(:quote_string)
    command.should_not respond_to(:not_a_command_method)
  end
  
end