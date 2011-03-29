# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/byte_array_spec'

describe 'DataObjects::Oracle with ByteArray' do
  include DataObjectsSpecHelpers

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

      before  do
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

      before  do
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

  describe 'inserting a large binary value' do

    before  do
      @binary_value = ::Extlib::ByteArray.new("\000\001\002\003\004"*1000)
      @result = @connection.create_command("INSERT INTO widgets (cad_drawing) VALUES (?) RETURNING id INTO :insert_id").
        execute_non_query(@binary_value)
      @reader = @connection.create_command("SELECT cad_drawing FROM widgets WHERE id = ?").execute_reader(@result.insert_id)
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
    end

    it 'should return the correct entry' do
      @values.first.should == @binary_value
    end

  end

end
