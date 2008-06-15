require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Transaction" do

  before(:all) do
    #@connection = mock("connection")
    #DataObjects::Connection.expects(:new).with("mock://mock/mock").times(1)

    #.and_return(@connection)
    #@transaction = DataObjects::Transaction.new("mock://mock/mock")

    @transaction = DataObjects::Jdbc::const_get('Transaction').new(Object)
    # TODO - replace with Mock
  end

  it "should inherit from DataObjects::Transaction" do
    @transaction.should be_kind_of(DataObjects::Transaction)
  end

  it "should have initialize, commit, rollback, save, create_command methods" do
    @transaction.should respond_to(:commit)
    @transaction.should respond_to(:rollback)
    @transaction.should respond_to(:save)
    @transaction.should respond_to(:create_command)
    @transaction.should_not respond_to(:not_a_transaction_method)
  end

end
