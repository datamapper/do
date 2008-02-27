# require File.dirname(__FILE__) + '/spec_helper'
require 'rubygems'
require '/usr/local/projects/do/data_objects/lib/data_objects'
require 'date'
require 'rbsqlite3'

describe "DataObjects::Sqlite3::Connection" do
  it "should connect" do
    connection = DataObjects::Connection.new("sqlite3:///usr/local/projects/do_svn/do_sqlite3/profile.db")
    connection.real_close
  end
end

describe "DataObjects::Sqlite3::Result" do
  it "should return the affected rows and insert_id" do    
    connection = DataObjects::Connection.new("sqlite3:///usr/local/projects/do_svn/do_sqlite3/profile.db")
    
    command = connection.create_command("INSERT INTO users (name) VALUES ('Joe Schmoe')")
    result = command.execute_non_query
    
    connection.real_close
  end
end

=begin
module DataObjects
  module Sqlite3
    class Connection < DataObjects::Connection
      
      def initialize
      end
      
      def begin_transaction
      end
      
      def real_close
      end
      
    end
    
    class Command < DataObjects::Command
      
      def set_types
      end
      
      def execute_non_query
      end
      
      def execute_reader
      end
      
    end
    
    class Result < DataObjects::Result
      
    end
    
    class Reader < DataObjects::Reader
      
      def close
      end
      
      def eof?
      end
      
      def next!
      end
      
      def values
      end
      
      def fields
      end
      
    end
  end
end
=end