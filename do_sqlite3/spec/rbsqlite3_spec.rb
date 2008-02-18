require 'date'
require 'rbsqlite3'

describe "RbSqlite3" do
  it "should exist" do
    Kernel.const_get('RbSqlite3').should_not be_nil
  end
  
  it "should expose a Connection class" do
    RbSqlite3.const_get('Connection').should_not be_nil
  end
  
  it "should expose a Result class" do
    RbSqlite3.const_get('Result').should_not be_nil
  end
  
  describe "a Connection" do
    before(:all) do
      @connection = RbSqlite3::Connection.new(File.dirname(__FILE__) + "/test.db")
    end
    
    it "should expose an #execute_reader method" do
      @connection.should respond_to(:execute_reader)
    end
    
    it "should expose an execute_non_query method" do
      @connection.should respond_to(:execute_non_query)
    end
    
    it "should expose a close method" do
      @connection.should respond_to(:close)
    end
  end
  
  describe "a Result" do
    before(:all) do
      @result = RbSqlite3::Result.new
    end
    
    it "should expose an affected_rows method" do
      @result.should respond_to(:affected_rows)
    end

    it "should expose a #field_count method" do
      @result.should respond_to(:field_count)
    end

    it "should expose a #field_names method" do
      @result.should respond_to(:field_names)
    end

    it "should expose a #field_types method" do
      @result.should respond_to(:field_types)
    end

    it "should expose a #inserted_id method" do
      @result.should respond_to(:inserted_id)
    end

    it "should expose a #fetch_row method" do
      @result.should respond_to(:fetch_row)
    end

    it "should expose a #close method" do
      @result.should respond_to(:close)
    end
  end
  
end

describe "A new connection" do
  before(:all) do    
    @connection = RbSqlite3::Connection.new(File.dirname(__FILE__) + "/test.db")
  end
  
  it "should be able to execute a query" do
    result = @connection.execute_reader("SELECT * FROM users")
    result.should be_kind_of(RbSqlite3::Result)
  end
  
  describe "executing a query" do
    before(:each) do
      @result = @connection.execute_reader("SELECT * FROM users LIMIT 2")
    end

    after(:each) do
      @result.close
    end

    it "shouldn't be able to determine the affected_rows" do
      @result.affected_rows.should be_nil
    end

    it "should return the proper number of fields" do
      @result.field_count.should == 2
    end

    it "should fetch 2 rows" do
      r = @result.fetch_row
      r.should be_kind_of(Array)
      puts @result.inspect
      puts r.inspect
      @result.fetch_row.should be_kind_of(Array)
      @result.fetch_row.should be_nil
    end
  end
  
  describe "executing an INSERT non-query" do
    it "should be able to determine the affected_rows" do
      result = @connection.execute_non_query("INSERT INTO users (name) VALUES ('Joe Namath')")
      result.affected_rows.should == 1
    end
    
    it "should yield the last inserted id" do
      @connection.execute_non_query("DELETE FROM users")

      result = @connection.execute_non_query("INSERT INTO users (name) VALUES ('Sam Smoot')")
      result.inserted_id.should == 1
      
      result = @connection.execute_non_query("INSERT INTO users (name) VALUES ('Ezra')")
      result.inserted_id.should == 2
    end
  end
end