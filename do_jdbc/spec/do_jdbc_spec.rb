require File.dirname(__FILE__) + '/spec_helper'

describe DataObjects::Jdbc do
  it "should expose the proper DataObjects classes" do
    DataObjects::Jdbc.const_get('Connection').should_not be_nil
    DataObjects::Jdbc.const_get('Command').should_not be_nil
    DataObjects::Jdbc.const_get('Result').should_not be_nil
    DataObjects::Jdbc.const_get('Reader').should_not be_nil
  end
  
  it "should connect successfully using the full URI" do
    DataObjects::Jdbc::Connection.
      new(URI.parse("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql"))
  end
end

describe DataObjects::Jdbc::Connection do
  before(:each) do
    # Open a connection for the specs to work with
    @connection = DataObjects::Jdbc::Connection.new("jdbc://postgres:pg123@localhost:5432/do_jdbc_test?driver=org.postgresql.Driver&protocol=postgresql")
  end

  it "should be able to create a command" do
    command = @connection.create_command("SELECT * FROM widgets")
    command.should be_kind_of(DataObjects::Jdbc::Command)
  end

  describe "executing a query" do
    before(:each) do
      @command = @connection.create_command("SELECT * FROM widgets LIMIT 2")
    end

    describe "reading results" do
      before(:each) do
	@reader = @command.execute_reader
      end
  
      it "should return the proper number of fields" do
	@reader.fields.size.should == 18
      end

      it "should fetch 2 rows" do
	@reader.next!.should == true
	@reader.values.should be_kind_of(Array)

	@reader.next!.should == true
	@reader.values.should be_kind_of(Array)
        
	@reader.next!.should be_nil
      end
    end

    describe "executing a query w/ set_types" do      
      before(:all) do
        @types = [
          Fixnum, String, String, String, String, String,
          String, Fixnum, Fixnum, Fixnum, Fixnum, Float, Float, 
	  BigDecimal, Date, DateTime, DateTime, String
        ]
      end

      before(:each) do
        @command = @connection.create_command("SELECT * FROM widgets LIMIT 2")
        @command.set_types @types
        @reader = @command.execute_reader
      end

      # HACK: This seems like a weak test
      it "should typecast all fields to the proper Ruby type" do
        @reader.next!

        @types.each_with_index do |t, idx|
          @reader.values[idx].class.should == t
        end
      end
    end
  end

  describe "executing a non-query" do
    it "should return a Result" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.should be_kind_of(DataObjects::Jdbc::Result)
    end

    it "should be able to determine the affected_rows" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.to_i.should == 1
    end
    
    it "should yield the last inserted id" do
      @connection.create_command("TRUNCATE TABLE invoices").execute_non_query
  
      result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')").execute_non_query
      result.insert_id.should == 1
      
      result = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('3456')").execute_non_query
      result.insert_id.should == 2
    end
  end
end
