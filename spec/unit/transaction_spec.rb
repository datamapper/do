require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Transaction" do
  
  it "should have initialize, commit, rollback, save, create_command methods" do
    transaction = DataObjects::Jdbc::const_get('Transaction').new(Object)
                                                      # TODO - replace with Mock
    transaction.should respond_to(:commit)
    transaction.should respond_to(:rollback)
    transaction.should respond_to(:save)
    transaction.should respond_to(:create_command)
    transaction.should_not respond_to(:not_a_transaction_method)
  end
  
end