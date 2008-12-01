require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Hsqldb::Result" do

  it "should inherit from DataObjects::Result" do
    pending
    #DataObjects::Jdbc::const_get('Result').new.should be_kind_of(DataObjects::Result)
  end

  #connection = DataObjects::Connection.new('jdbc://localhost')
  #command = connection.create_command("SELECT * FROM example")
  #result = command.execute_non_query

  # In case the driver needs to access the command or connection to load additional data.
  #result.instance_variables.should include('@command')

  # Affected Rows:
  #result.should respond_to(:to_i)
  #result.to_i.should == 0

  # The id of the inserted row.
  #result.should respond_to(:insert_id)
end
