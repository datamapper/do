require File.dirname(__FILE__) + '/spec_helper'

describe "RbMysql" do
  it "should exist" do
    Kernel.const_get('RbMysql').should_not be_nil
  end
  
  it "should expose a Connection class" do
    RbMysql.const_get('Connection').should_not be_nil
  end

  it "should expose a Result class" do
    RbMysql.const_get('Result').should_not be_nil
  end
  
  describe "a Connection" do
    before(:all) do
      @connection = RbMysql::Connection.new('localhost', 'root', '', 'rbmysql_test', 3306, nil, nil)
    end
    
    it "should expose a #execute_reader method" do
      @connection.should respond_to(:execute_reader)
    end

    it "should expose a #execute_non_query method" do
      @connection.should respond_to(:execute_non_query)
    end

    it "should expose a #close method" do
      @connection.should respond_to(:close)
    end
  end
  
  describe "a Result" do
    before(:all) do
      @result = RbMysql::Result.new
    end
    
    it "should expose a #affected_rows method" do
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

    it "should expose a #set_types method" do
      @result.should respond_to(:set_types)
    end

  end
    
end

describe "A new connection" do
  before(:all) do
    # Run the rbmysql.sql script on your local Mysql install.  This will drop/create a
    # database called "rbmysql_test" and add a couple tables and a few records for
    # testing purposes
    `mysql -u root < #{File.dirname(__FILE__)}/rbmysql.sql`
    
    # Open a connection for the specs to work with
    @connection = RbMysql::Connection.new('127.0.0.1', 'root', '', 'rbmysql_test', 3306, nil, nil)
  end
  
  it "should be able to execute a query" do
    result = @connection.execute_reader("SELECT * FROM widgets")
    result.should be_kind_of(RbMysql::Result)
  end
  
  describe "executing a query" do
    before(:each) do
      @result = @connection.execute_reader("SELECT * FROM widgets LIMIT 2")
    end

    after(:each) do
      @result.close
    end

    it "shouldn't be able to determine the affected_rows" do
      @result.affected_rows.should be_nil
    end

    it "should return the proper number of fields" do
      @result.field_count.should == 21
    end

    it "should fetch 2 rows" do
      @result.fetch_row.should be_kind_of(Array)
      @result.fetch_row.should be_kind_of(Array)
      @result.fetch_row.should be_nil
    end
    
    it "should contain tainted strings" do
      @result.fetch_row[1].should be_tainted
    end
    
    # HACK: this is a weak test...
    it "should typecast all fields to the proper Ruby type" do

      @result.set_types [
        Fixnum,
        String,
        String,
        String, 
        String,
        String,
        String,
        String, 
        String,
        String,
        FalseClass,
        Fixnum,
        Fixnum, 
        Bignum,
        Float,
        Float,
        Float, 
        Date,
        DateTime,
        DateTime,
        String
      ]
      
      row = @result.fetch_row

      types = [
        Fixnum,
        String,
        String,
        String, 
        String,
        String,
        String,
        String, 
        String,
        String,
        FalseClass,
        Fixnum,
        Fixnum, 
        Bignum,
        Float,
        Float,
        Float, 
        Date,
        DateTime,
        DateTime,
        String
      ]
      
      types.each_with_index do |t, idx|
        # puts row[idx].class
        # puts "Field #{idx} - #{@result.field_names[idx]}/#{@result.field_types[idx]}: #{row[idx].inspect}"
        row[idx].class.should == types[idx]
      end
    end
    
  end
  
  describe "executing an INSERT non-query" do
    it "should be able to determine the affected_rows" do
      result = @connection.execute_non_query("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result.affected_rows.should == 1
    end
    
    it "should yield the last inserted id" do
      @connection.execute_non_query("TRUNCATE TABLE invoices")

      result = @connection.execute_non_query("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result.inserted_id.should == 1
      
      result = @connection.execute_non_query("INSERT INTO invoices (invoice_number) VALUES ('3456')")
      result.inserted_id.should == 2
    end
  end
  
  describe "executing an UPDATE non-query" do
    it "should be able to determine the affected_rows" do
      [
        "TRUNCATE TABLE invoices",
        "INSERT INTO invoices (invoice_number) VALUES ('1234')",
        "INSERT INTO invoices (invoice_number) VALUES ('1234')"
      ].each { |q| @connection.execute_non_query(q) }

      result = @connection.execute_non_query("UPDATE invoices SET invoice_number = '3456'")
      result.affected_rows.should == 2
    end
  end
  
  describe "executing an INVALID non-query" do
    it "should return nil instead of a reader" do
      result = @connection.execute_non_query("UPDwhoopsATE invoices SET invoice_number = '3456'")
      result.should be_nil
      
      @connection.last_error.should_not be_nil
      @connection.last_error.should be_kind_of(String)
    end
  end
  
end