require File.dirname(__FILE__) + '/spec_helper'

describe "DataObjects::JDBC" do
  
  it "should expose the proper DataObjects classes" do
    
    lambda {
      DataObjects::JDBC::const_get('Command')
      DataObjects::JDBC::const_get('Connection')
      DataObjects::JDBC::const_get('Result')
      DataObjects::JDBC::const_get('Reader')     
      DataObjects::JDBC::const_get('Transaction')
    }.should_not raise_error(NameError)
    
    lambda {
      DataObjects::JDBC::const_get('NotAClass')
    }.should raise_error(NameError)

    DataObjects::JDBC::const_get('Command').should_not be_nil
    DataObjects::JDBC::const_get('Connection').should_not be_nil
    DataObjects::JDBC::const_get('Result').should_not be_nil
    DataObjects::JDBC::const_get('Reader').should_not be_nil        
    DataObjects::JDBC::const_get('Transaction').should_not be_nil
    
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

describe "DataObjects::JDBC::Command" do
  
  it "should have set_types, execute_non_query, execute_reader and quote_string methods" do
    command = DataObjects::JDBC::const_get('Command').new(Object, Object)
                                                        # TODO: replace with mocks
    command.should respond_to(:set_types)
    #command.respond_to?('execute_non_query').should == true
    #command.respond_to?('execute_reader').should == true
    #command.respond_to?('quote_string').should == true
    command.should_not respond_to(:not_a_command_method)
  end
  
end

describe "DataObjects::JDBC::Connection" do
  
  it "should have initialize, using_socket?, character_set, real_close methods" do
    #connection = DataObjects::JDBC::const_get('Connection').new("JDBC://test/")
    #connection.respond_to?('using_socket?').should == true
    #connection.respond_to?('character_set').should == true
    #connection.respond_to?('real_close').should == true
    #connection.respond_to?('begin_transaction').should == true
    #connection.respond_to?('not_a_conn_method').should == true
  end
  
end

describe "DataObjects::JDBC::Reader" do
  
  it "should have close, should, values, fields methods" do
    reader = DataObjects::JDBC::const_get('Reader').new
    reader.should respond_to(:close)
    reader.should respond_to(:next!)
    reader.should respond_to(:values)
    reader.should respond_to(:fields)
    reader.should_not respond_to(:not_a_reader_method)
  end
  
end

describe "DataObjects::JDBC::Result" do
  
end

describe "DataObjects::JDBC::Transaction" do
  
  it "should have initialize, commit, rollback, save, create_command methods" do
    transaction = DataObjects::JDBC::const_get('Transaction').new(Object)
                                                      # TODO - replace with Mock
    transaction.should respond_to(:commit)
    transaction.should respond_to(:rollback)
    transaction.should respond_to(:save)
    #transaction.respond_to?('create_command').should == true
    transaction.should_not respond_to(:not_a_transaction_method)
  end
  
end