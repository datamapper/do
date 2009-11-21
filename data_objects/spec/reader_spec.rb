require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Reader do

  it "should define a standard API" do
    connection = DataObjects::Connection.new('mock://localhost')

    command = connection.create_command("SELECT * FROM example")

    reader = command.execute_reader

    reader.should.be.kind_of(Enumerable)

    reader.should.respond_to(:close)
    reader.should.respond_to(:next!)
    reader.should.respond_to(:values)
    reader.should.respond_to(:fields)
    reader.should.respond_to(:each)

    connection.close
  end

end
