# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/datetime_spec'

describe 'DataObjects::Mysql with DateTime' do
  it_should_behave_like 'supporting DateTime'
  it_should_behave_like 'supporting DateTime autocasting'

  describe 'reading 0000-00-00 00:00:00' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)

      @connection.create_command("SET SESSION sql_mode = 'ALLOW_INVALID_DATES'").execute_non_query
      @connection.create_command("INSERT INTO widgets (release_datetime) VALUES ('')").execute_non_query

      @command = @connection.create_command("SELECT release_datetime FROM widgets WHERE release_datetime = '0000-00-00 00:00:00'")
      @reader = @command.execute_reader
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
      @connection.close
    end

    it 'should return the number of created rows' do
      @values.first.should be_nil
    end

  end

end
