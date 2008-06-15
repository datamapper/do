require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe DataObjects::Jdbc::Command do

  before(:each) do
    @connection = DataObjects::Jdbc::Connection.new("jdbc:hsqldb:mem")
  end

  describe "Executing a Reader" do

    it "should log reader queries when the level is Debug (0)" do
      command = @connection.create_command("SELECT * FROM widgets WHERE name = ?")
      @mock_logger = mock('MockLogger', :level => 0)
      DataObjects::Jdbc.expects(:logger).returns(@mock_logger)
      @mock_logger.expects(:debug) #.with("SELECT * FROM widgets WHERE name = 'Scott'")
      command.execute_reader('Scott')
    end

    it "shouldn't log reader queries when the level isn't Debug (0)" do
      command = @connection.create_command("SELECT * FROM widgets WHERE name = ?")
      @mock_logger = mock('MockLogger', :level => 1)
      DataObjects::Jdbc.expects(:logger).returns(@mock_logger)
      @mock_logger.expects(:debug).never
      command.execute_reader('Scott')
    end
  end

  describe "Executing a Non-Query" do
    it "should log non-query statements when the level is Debug (0)" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES (?)")
      @mock_logger = mock('MockLogger', :level => 0)
      DataObjects::Jdbc.expects(:logger).returns(@mock_logger)
      @mock_logger.expects(:debug) #.with("INSERT INTO invoices (invoice_number) VALUES (1234)")
      command.execute_non_query('Blah')
    end

    it "shouldn't log non-query statements when the level isn't Debug (0)" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES (?)")
      @mock_logger = mock('MockLogger', :level => 1)
      DataObjects::Jdbc.expects(:logger).returns(@mock_logger)
      @mock_logger.expects(:debug).never
      command.execute_non_query('Blah')
    end
  end

end
