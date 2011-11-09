# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/date_spec'

describe 'DataObjects::Postgres with Date' do
  it_should_behave_like 'supporting Date'
  it_should_behave_like 'supporting Date autocasting'

  describe 'exotic dates' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
      @connection.create_command("INSERT INTO widgets (release_date) VALUES ('0001-01-01')").execute_non_query

      @command = @connection.create_command("SELECT release_date FROM widgets WHERE release_date = '0001-01-01'")
      @reader = @command.execute_reader
      @reader.next!
      @values = @reader.values
    end

    after do
      @reader.close
      @connection.close
    end

    it 'should return the number of created rows' do
      @values.first.should == Date.civil(1, 1, 1)
    end

  end

end
