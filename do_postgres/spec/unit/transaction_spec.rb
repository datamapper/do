require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe DataObjects::Postgres::Transaction do

  before :each do
    @connection = mock("connection")
    DataObjects::Connection.should_receive(:new).with("mock://mock/mock").once.and_return(@connection)
    @transaction = DataObjects::Postgres::Transaction.new("mock://mock/mock")
    @transaction.id.replace("id")
    @command = mock("command")
  end

  {
    :begin => "BEGIN",
    :commit => "COMMIT PREPARED 'id'",
    :rollback => "ROLLBACK",
    :rollback_prepared => "ROLLBACK PREPARED 'id'",
    :prepare => "PREPARE TRANSACTION 'id'"
  }.each do |method, command|
    it "should execute #{command} on ##{method}" do
      @command.should_receive(:execute_non_query).once
      @connection.should_receive(:create_command).once.with(command).and_return(@command)
      @transaction.send(method)
    end
  end

end
