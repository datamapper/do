# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/connection_spec'

describe DataObjects::Postgres::Connection do

  before :all do
    @driver = CONFIG.scheme
    @user   = CONFIG.user
    @password = CONFIG.pass
    @host   = CONFIG.host
    @port   = CONFIG.port
    @database = CONFIG.database
  end

  it_should_behave_like 'a Connection'
  it_should_behave_like 'a Connection with authentication support'
  it_should_behave_like 'a Connection allowing default database' unless JRUBY
  it_should_behave_like 'a Connection with JDBC URL support' if JRUBY

  describe 'byte array quoting' do

    before do
      @connection = DataObjects::Connection.new(CONFIG.uri)
    end

    after do
      @connection.close
    end

    # There are two possible byte array quotings available: hex or escape.
    # The default changed from escape to hex in version 9, so these specs
    # check for either.
    #
    # http://developer.postgresql.org/pgdocs/postgres/datatype-binary.html
    # http://developer.postgresql.org/pgdocs/postgres/release-9-0.html (E.3.2.3.)
    it 'should properly escape non-printable ASCII characters' do
      ["'\\001'", "'\\x01'"].should include @connection.quote_byte_array("\001")
    end

    it 'should properly escape bytes with the high bit set' do
      ["'\\210'", "'\\x88'"].should include @connection.quote_byte_array("\210")
    end

    it 'should not escape printable ASCII characters' do
      ["'a'", "'\\x61'"].should include @connection.quote_byte_array("a")
    end
  end
end
