# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/nil_spec'

describe 'DataObjects::Oracle with Nil' do
  it_should_behave_like 'supporting Nil'
  # it_should_behave_like 'supporting writing an Nil'

  describe 'supporting writing an Nil' do

    describe 'as a parameter' do

        before  do
          # @reader = @connection.create_command("SELECT id FROM widgets WHERE ad_description IS ?").execute_reader(nil)
          # NULL can't be passed as bind variable for "IS ?"
          @reader = @connection.create_command("SELECT id FROM widgets WHERE ad_description IS NULL").execute_reader
          @reader.next!
          @values = @reader.values
        end

        after do
          @reader.close
        end

        it 'should return the correct entry' do
          #Some of the drivers starts autoincrementation from 0 not 1
          @values.first.should satisfy { |val| val == 3 or val == 2 }
        end

    end

  end

  it_should_behave_like 'supporting Nil autocasting'
end
