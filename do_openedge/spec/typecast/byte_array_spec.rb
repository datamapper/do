# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

# Can't use full shared spec due to ProKB P91964
#require 'data_objects/spec/shared/typecast/byte_array_spec'

describe 'supporting ByteArray' do

  before :all do
    setup_test_environment
  end

  before do
    @connection = DataObjects::Connection.new(CONFIG.uri)
  end

  after do
    @connection.close
  end

  describe 'reading a ByteArray' do

    describe 'with automatic typecasting' do

      before do
        @reader = @connection.create_command("SELECT cad_drawing FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(::Extlib::ByteArray)
      end

      it 'should return the correct result' do
        @values.first.should == "CAD \001 \000 DRAWING"
      end

    end

    describe 'with manual typecasting' do

      before do
        @command = @connection.create_command("SELECT cad_drawing FROM widgets WHERE ad_description = ?")
        @command.set_types(::Extlib::ByteArray)
        @reader = @command.execute_reader('Buy this product now!')
        @reader.next!
        @values = @reader.values
      end

      after do
        @reader.close
      end

      it 'should return the correctly typed result' do
        @values.first.should be_kind_of(::Extlib::ByteArray)
      end

      it 'should return the correct result' do
        @values.first.should == "CAD \001 \000 DRAWING"
      end

    end

  end

# CLOB/BLOB fields cannot be used in a query predicate. See ProKB P91964:
# http://knowledgebase.progress.com/articles/Article/P91964

=begin
  describe 'writing a ByteArray' do

    before do
      @reader = @connection.create_command("SELECT ad_description FROM widgets WHERE cad_drawing = ?").execute_reader(::Extlib::ByteArray.new("CAD \001 \000 DRAWING"))
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      #Some of the drivers starts autoincrementation from 0 not 1
      @values.first.should == 'Buy this product now!'
    end

  end
=end

end
