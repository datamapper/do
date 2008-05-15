require File.dirname(__FILE__) + '/spec_helper'

describe "DataObjects::Jdbc" do
  
  it "should expose the proper DataObjects classes" do
    
    lambda {
      DataObjects::Jdbc::const_get('Command')
      DataObjects::Jdbc::const_get('Connection')
      DataObjects::Jdbc::const_get('Result')
      DataObjects::Jdbc::const_get('Reader')     
      DataObjects::Jdbc::const_get('Transaction')
    }.should_not raise_error(NameError)
    
    lambda {
      DataObjects::Jdbc::const_get('NotAClass')
    }.should raise_error(NameError)

    DataObjects::Jdbc::const_get('Command').should_not be_nil
    DataObjects::Jdbc::const_get('Connection').should_not be_nil
    DataObjects::Jdbc::const_get('Result').should_not be_nil
    DataObjects::Jdbc::const_get('Reader').should_not be_nil        
    DataObjects::Jdbc::const_get('Transaction').should_not be_nil
    
    #DataObjects::JDBC::const_get('Command').should be_kind_of(DataObjects::Command)
    #DataObjects::JDBC::const_get('Connection').should be_kind_of(DataObjects::Connection)    
    #DataObjects::JDBC::const_get('Result').should be_kind_of(DataObjects::Result)
    #DataObjects::JDBC::const_get('Reader').should be_kind_of(DataObjects::Reader)
    #DataObjects::JDBC::const_get('Transaction').should be_kind_of(DataObjects::Transaction)
    
    #puts(DataObjects::JDBC::const_get('Reader').kind_of?(DataObjects::Reader))
    #puts(DataObjects::JDBC::const_get('Reader').inspect)
  end
  
  it "should raise error on bad connection string" 
  
  it "should connect successfully via TCP" 
  it "should connect successfully via the socket file"
  it "should return the current character set"
  it "should support changing the character set"
  
end

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

describe "DataObjects::Jdbc::Connection" do
  
  it "should have initialize, using_socket?, character_set, real_close methods" do
    connection = DataObjects::Jdbc::const_get('Connection').new("jdbc://test/")

    connection.should respond_to(:real_close)
    connection.should_not respond_to(:not_a_conn_method)
    
  end
  
  it "should be able to create a command" do
    @connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")
    
    command = @connection.create_command("SELECT * FROM widgets")
    command.should be_kind_of(DataObjects::Jdbc::Command)
  end
  
  it "should return a Result" do
    @connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")

    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.should be_kind_of(DataObjects::Jdbc::Result)
  end

  it "should be able to determine the affected_rows" do
    @connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")

    command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
    result = command.execute_non_query
    result.to_i.should == 1
  end
  
end

describe "DataObjects::Jdbc::Reader" do
  
  it "should have close, should, values, fields methods" do
    reader = DataObjects::Jdbc::const_get('Reader').new
    reader.should respond_to(:close)
    reader.should respond_to(:next!)
    reader.should respond_to(:values)
    reader.should respond_to(:fields)
    reader.should_not respond_to(:not_a_reader_method)
  end
  
end

describe "DataObjects::Jdbc::Result" do
  
end

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