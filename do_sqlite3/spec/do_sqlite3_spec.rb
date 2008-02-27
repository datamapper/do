# require File.dirname(__FILE__) + '/spec_helper'
require 'date'
require 'rbsqlite3'

describe "do_sqlite3" do
  it "should do nothing" do
    true.should == true
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