# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/encoding_spec'

describe DataObjects::Mysql::Connection do
  it_should_behave_like 'a driver supporting different encodings'
  it_should_behave_like 'returning correctly encoded strings for the default database encoding'
  it_should_behave_like 'returning correctly encoded strings for the default internal encoding' unless JRUBY

  unless JRUBY
    describe 'sets the character set through the URI' do
      before do
        @utf8mb4_connection = DataObjects::Connection.new("#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}?encoding=UTF-8-MB4")
      end

      after { @utf8mb4_connection.close }

      it { @utf8mb4_connection.character_set.should == 'UTF-8-MB4' }

      describe 'writing a multibyte String' do
        it 'should write a multibyte String' do
          @command = @utf8mb4_connection.create_command('INSERT INTO users_mb4 (name) VALUES(?)')
          expect { @command.execute_non_query("😀") }.not_to raise_error(DataObjects::DataError)
        end
      end

      describe 'reading a String' do
        before do
          @reader = @utf8mb4_connection.create_command("SELECT name FROM users_mb4").execute_reader
          @reader.next!
          @values = @reader.values
        end

        after do
          @reader.close
        end

        it 'should return UTF-8 encoded String' do
          @values.first.should be_kind_of(String)
          @values.first.encoding.name.should == 'UTF-8'
          @values.first.should == "😀"
        end
      end
    end
  end
end
