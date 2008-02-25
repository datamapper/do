require File.dirname(__FILE__) + '/spec_helper'

describe "DataObjects Mysql Adapter" do

  # TODO: obviously...
  it "should work" do
    connection = DataObjects::Connection.new('mysql://root@localhost/rbmysql_test')
    command = connection.create_command("SELECT * FROM widgets")
    # command.set_types [
    #   Fixnum, String,String,String, String,String,String,String,String,String,
    #     FalseClass,Fixnum,Fixnum, Bignum,Float,Float,Float, Date,DateTime,DateTime,String
    # ]
    
    reader = command.execute_reader
    
    until reader.eof?
      puts reader.values
      reader.next!
    end
    
    reader.close
  end

end