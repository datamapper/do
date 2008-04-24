require File.dirname(__FILE__) + '/spec_helper'

def setup_test_environment
  @connection = DataObjects::Mysql::Connection.new("mysql://127.0.0.1/do_mysql_test")
  @connection.create_command(<<EOF
DROP TABLE `invoices`
EOF
                             ).execute_non_query
  @connection.create_command(<<EOF
DROP TABLE `widgets`
EOF
                             ).execute_non_query
  @connection.create_command(<<EOF
CREATE TABLE `invoices` (
  `id` int(11) NOT NULL auto_increment,
  `invoice_number` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF
                             ).execute_non_query
  @connection.create_command(<<EOF
CREATE TABLE `widgets` (
  `id` int(11) NOT NULL auto_increment,
  `code` char(8) default 'A14' NULL,
  `name` varchar(200) default 'Super Widget' NULL,
  `shelf_location` tinytext NULL,
  `description` text NULL,
  `image_data` blob NULL,
  `ad_description` mediumtext NULL,
  `ad_image` mediumblob NULL,
  `whitepaper_text` longtext NULL,
  `cad_drawing` longblob NULL,
  `flags` tinyint(1) default 0,
  `number_in_stock` smallint default 500,
  `number_sold` mediumint default 0,
  `super_number` bigint default 9223372036854775807,
  `weight` float default 1.23,
  `cost1` double(8,2) default 10.23,
  `cost2` decimal(8,2) default 50.23,
  `release_date` date default '2008-02-14',
  `release_datetime` datetime default '2008-02-14 00:31:12',
  `release_timestamp` timestamp default '2008-02-14 00:31:31',
  `status` enum('active','out of stock') NOT NULL default 'active',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
EOF
                             ).execute_non_query
  1.upto(16) do |n|
    @connection.create_command(<<EOF
insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING', 1234);
EOF
                               ).execute_non_query
  end
end

describe DataObjects::Mysql do

  it "should expose the proper DataObjects classes" do
    DataObjects::Mysql.const_get('Connection').should_not be_nil
    DataObjects::Mysql.const_get('Command').should_not be_nil
    DataObjects::Mysql.const_get('Result').should_not be_nil
    DataObjects::Mysql.const_get('Reader').should_not be_nil
  end
  
  it "should connect successfully via TCP" do
    connection = DataObjects::Mysql::Connection.new("mysql://root@127.0.0.1:3306/do_mysql_test")
    connection.should_not be_using_socket
  end

#
#  I comment this out partly to raise the issue for discussion. Socket files are afaik not supported under windows. Does this
#  mean that we should test for it on unix boxes but not on windows boxes? Or does it mean that it should not be speced at all?
#  It's not really a requirement, since all architectures that support MySQL also supports TCP connectsion, ne?
#
#  it "should connect successfully via the socket file" do
#    @connection = DataObjects::Mysql::Connection.new("mysql://root@localhost:3306/do_mysql_test/?socket=#{SOCKET_PATH}")
#    @connection.should be_using_socket
#  end
  
  it "should return the current character set" do
    connection = DataObjects::Mysql::Connection.new("mysql://root@localhost:3306/do_mysql_test")
    connection.character_set.should == "utf8"
  end
  
  it "should support changing the character set" do
    connection = DataObjects::Mysql::Connection.new("mysql://root@localhost:3306/do_mysql_test/?charset=latin1")
    connection.character_set.should == "latin1"

    @connection = DataObjects::Mysql::Connection.new("mysql://root@localhost:3306/do_mysql_test/?charset=utf8")
    @connection.character_set.should == "utf8"
  end
  
  it "should raise an error when opened with an invalid server uri" do
    def connecting_with(uri)
      lambda { DataObjects::Mysql::Connection.new(uri) }
    end
    
    # Missing database name
    connecting_with("mysql://root@localhost:3306/").should raise_error(MysqlError)
    
    # Wrong port
    connecting_with("mysql://root@localhost:666/").should raise_error(MysqlError)
    
    # Bad Username
    connecting_with("mysql://baduser@localhost:3306/").should raise_error(MysqlError)
    
    # Bad Password
    connecting_with("mysql://root:wrongpassword@localhost:3306/").should raise_error(MysqlError)
    
    # Bad Database Name
    connecting_with("mysql://root@localhost:3306/bad_database").should raise_error(MysqlError)
    
    #
    # Again, should socket even be speced if we don't support it across all platforms?
    #
    # Invalid Socket Path
    #connecting_with("mysql://root@localhost:3306/do_mysql_test/?socket=/invalid/path/mysql.sock").should raise_error(MysqlError)
  end
end

describe DataObjects::Mysql::Connection do

  before :all do
    setup_test_environment
  end
  
  it "should be able to create a command" do
    command = @connection.create_command("SELECT * FROM widgets")
    command.should be_kind_of(DataObjects::Mysql::Command)
  end

  it "should raise an error when attempting to execute a bad query" do
    lambda { @connection.create_command("INSERT INTO non_existant_table (tester) VALUES (1)").execute_non_query }.should raise_error(MysqlError)
    lambda { @connection.create_command("SELECT * FROM non_existant table").execute_reader }.should raise_error(MysqlError)
  end

  describe "executing a query" do
    
    it "should escape strings properly" do
      command = @connection.create_command("SELECT * FROM widgets WHERE name = ?")
      command.quote_string("Willy O'Hare & Johnny O'Toole").should == "'Willy O\\'Hare & Johnny O\\'Toole'".dup
      command.quote_string("The\\Backslasher\\Rises\\Again").should == "'The\\\\Backslasher\\\\Rises\\\\Again'"
      command.quote_string("Scott \"The Rage\" Bauer").should == "'Scott \\\"The Rage\\\" Bauer'"
    end
    
    it "should allow backslash string-escaping" do
      reader = @connection.create_command("SELECT * FROM widgets WHERE name = ?").execute_reader("Willy O\'Hare")
    end
    
    describe "reading results" do
      before(:each) do
        @command = @connection.create_command("SELECT * FROM widgets LIMIT 2")
        @reader = @command.execute_reader
      end
  
      after(:each) do
        @reader.close
      end
      
      it "should return the proper number of fields" do
        @reader.fields.size.should == 21
      end
  
      it "should return raise an exception if .values is called after reading all available rows" do
        3.times { @reader.next! }
        lambda { @reader.values }.should raise_error(Exception)
      end
  
      it "should fetch 2 rows" do
        @reader.next!.should == true
        @reader.values.should be_kind_of(Array)
        
        @reader.next!.should == true
        @reader.values.should be_kind_of(Array)
        
        @reader.next!.should be_nil
      end
      
      it "should contain tainted strings" do
        @reader.next!
  
        @reader.values.each do |value|
          (value.should be_tainted) if value.is_a?(String)
        end
      end
    
      # it "should NOT be closed after fetching all rows" do
      #   2.times { @result.fetch_row }
      #   @result.should_not be_closed
      # end
      # 
      # it "should be closeable before fetching all rows" do
      #   @result.close.should == true
      # end
    end
    
    describe "executing a query w/ set_types" do      
      before(:all) do
        @types = [
          Fixnum, String, String, String, String, String,
          String, String, String, String, FalseClass, Fixnum, Fixnum, 
          Bignum, BigDecimal, BigDecimal, BigDecimal, Date, DateTime, DateTime, String
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
          @reader.values[idx].class.should == @types[idx]
        end
      end

    end

  end
  
  # An awful lot of setup here just to get a typecast value back...
  def type_test(value, type_string, ruby_type = nil)
    test_table = "test_table_#{rand(10000)}"
    value = 'null' if value.nil?
    @connection.create_command("DROP TABLE IF EXISTS #{test_table}").execute_non_query
    @connection.create_command("CREATE TABLE `#{test_table}` ( `test_field` #{type_string} )").execute_non_query
    @connection.create_command("INSERT INTO #{test_table} (test_field) VALUES (#{value})").execute_non_query
    @cmd = @connection.create_command("SELECT test_field FROM #{test_table}")
    @cmd.set_types [ruby_type || value.class]
    @reader = @cmd.execute_reader
    @reader.next!
    value = @reader.values[0]
    @reader.close
    value
  end
  
  describe "executing a non-query" do
    it "should return a Result" do
      command = @connection.create_command("INSERT INTO invoices (invoice_number) VALUES ('1234')")
      result = command.execute_non_query
      result.should be_kind_of(DataObjects::Mysql::Result)
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
  
    it "should be able to determine the affected_rows" do
      [
        "TRUNCATE TABLE invoices",
        "INSERT INTO invoices (invoice_number) VALUES ('1234')",
        "INSERT INTO invoices (invoice_number) VALUES ('1234')"
      ].each { |q| @connection.create_command(q).execute_non_query }
  
      result = @connection.create_command("UPDATE invoices SET invoice_number = '3456'").execute_non_query
      result.to_i.should == 2
    end
    
    it "should raise an error when executing an invalid query" do
      command = @connection.create_command("UPDwhoopsATE invoices SET invoice_number = '3456'")
  
      lambda { command.execute_non_query }.should raise_error(Exception)
    end
  
  end
  
end
