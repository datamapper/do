require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe DataObjects::Hsqldb::Command do

  before(:each) do
    @connection = DataObjects::Hsqldb::Connection.new("jdbc:hsqldb:mem")
  end

  describe "Executing a Reader" do

    it "should log reader queries when the level is Debug (0)" do
      command = @connection.create_command("SELECT * FROM widgets WHERE name = ?")
      @mock_logger = mock('MockLogger', :level => 0)
      DataObjects::Hsqldb.should_receive(:logger).and_return(@mock_logger)
      @mock_logger.should_receive(:debug).with(/\([\d.]+\) SELECT \* FROM widgets WHERE name = 'Scott'/)
      command.execute_reader('Scott').close
    end

    it "shouldn't log reader queries when the level isn't Debug (0)" do
      command = @connection.create_command("SELECT * FROM widgets WHERE name = ?")
      @mock_logger = mock('MockLogger', :level => 1)
      DataObjects::Hsqldb.should_receive(:logger).and_return(@mock_logger)
      @mock_logger.should_receive(:debug).never
      command.execute_reader('Scott').close
    end
  end

  describe "Executing a Non-Query" do
    it "should log non-query statements when the level is Debug (0)" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES (?)")
      @mock_logger = mock('MockLogger', :level => 0)
      DataObjects::Hsqldb.should_receive(:logger).and_return(@mock_logger)
      @mock_logger.should_receive(:debug) #.with("INSERT INTO invoices (invoice_number) VALUES (1234)")
      command.execute_non_query('Blah')
    end

    it "shouldn't log non-query statements when the level isn't Debug (0)" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES (?)")
      @mock_logger = mock('MockLogger', :level => 1)
      DataObjects::Hsqldb.should_receive(:logger).and_return(@mock_logger)
      @mock_logger.should_receive(:debug).never
      command.execute_non_query('Blah')
    end
  end

end
