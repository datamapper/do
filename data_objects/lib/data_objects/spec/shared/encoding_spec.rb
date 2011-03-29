shared_examples_for 'a driver supporting different encodings' do

  describe 'character_set' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
    end

    after do
      @connection.close
    end

    it { @connection.should respond_to(:character_set) }

    it 'uses utf8 by default' do
      @connection.character_set.should == 'UTF-8'
    end

    describe 'sets the character set through the URI' do
      before do
        # @latin1_connection = DataObjects::Connection.new("#{CONFIG.uri}?encoding=latin1")
        @latin1_connection = DataObjects::Connection.new("#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}?encoding=ISO-8859-1")
      end

      after { @latin1_connection.close }

      it { @latin1_connection.character_set.should == 'ISO-8859-1' }
    end

    describe 'uses UTF-8 when an invalid encoding is given' do
      before do
        @latin1_connection = DataObjects::Connection.new("#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}?encoding=ISO-INVALID")
      end

      after { @latin1_connection.close }

      it { @latin1_connection.character_set.should == 'UTF-8' }
    end
  end
end

shared_examples_for 'returning correctly encoded strings for the default database encoding' do

  if defined?(::Encoding)

    before :all do
    setup_test_environment
  end

    describe 'with encoded string support' do

      before do
        @connection = DataObjects::Connection.new(CONFIG.uri)
      end

      after do
        @connection.close
      end

      describe 'reading a String' do
        before do
          @reader = @connection.create_command("SELECT name, whitepaper_text FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
          @reader.next!
          @values = @reader.values
        end

        after do
          @reader.close
        end

        it 'should return UTF-8 encoded String' do
          @values.first.should be_kind_of(String)
          @values.first.encoding.name.should == 'UTF-8'
          @values.last.should be_kind_of(String)
          @values.last.encoding.name.should == 'UTF-8'
        end
      end

      describe 'reading a ByteArray' do
        before do
          @command = @connection.create_command("SELECT ad_image FROM widgets WHERE ad_description = ?")
          @command.set_types(Extlib::ByteArray)
          @reader = @command.execute_reader('Buy this product now!')
          @reader.next!
          @values = @reader.values
        end

        after do
          @reader.close
        end

        it 'should return ASCII-8BIT encoded ByteArray' do
          @values.first.should be_kind_of(::Extlib::ByteArray)
          @values.first.encoding.name.should == 'ASCII-8BIT'
        end
      end
    end
  end

end

shared_examples_for 'returning correctly encoded strings for the default internal encoding' do

  if defined?(::Encoding)

    before :all do
    setup_test_environment
  end

    describe 'with encoded string support' do

      before do
        @encoding_before = Encoding.default_internal
        Encoding.default_internal = 'ISO-8859-1'
        @connection = DataObjects::Connection.new(CONFIG.uri)
      end

      after do
        @connection.close
        Encoding.default_internal = @encoding_before
      end

      describe 'reading a String' do
        before do
          @reader = @connection.create_command("SELECT name, whitepaper_text FROM widgets WHERE ad_description = ?").execute_reader('Buy this product now!')
          @reader.next!
          @values = @reader.values
        end

        after do
          @reader.close
        end

        it 'should return ISO-8859-1 encoded String' do
          @values.first.should be_kind_of(String)
          @values.first.encoding.name.should == 'ISO-8859-1'
          @values.last.should be_kind_of(String)
          @values.last.encoding.name.should == 'ISO-8859-1'
        end
      end

      describe 'reading a ByteArray' do
        before do
          @command = @connection.create_command("SELECT ad_image FROM widgets WHERE ad_description = ?")
          @command.set_types(Extlib::ByteArray)
          @reader = @command.execute_reader('Buy this product now!')
          @reader.next!
          @values = @reader.values
        end

        after do
          @reader.close
        end

        it 'should return ASCII-8BIT encoded ByteArray' do
          @values.first.should be_kind_of(::Extlib::ByteArray)
          @values.first.encoding.name.should == 'ASCII-8BIT'
        end
      end
    end
  end

end
