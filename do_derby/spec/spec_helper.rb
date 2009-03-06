$TESTING=true

require 'rubygems'

gem 'rspec', '~>1.1.12'
require 'spec'

require 'date'
require 'pathname'
require 'fileutils'

# put data_objects from repository in the load path
# DO NOT USE installed gem of data_objects!
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data_objects', 'lib'))
require 'data_objects'

DATAOBJECTS_SPEC_ROOT = Pathname(__FILE__).dirname.parent.parent + 'data_objects' + 'spec'
Pathname.glob((DATAOBJECTS_SPEC_ROOT + 'lib/**/*.rb').to_s).each { |f| require f }

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'do_jdbc', 'lib'))
require 'do_jdbc'

# put the pre-compiled extension in the path to be found
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'do_derby'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::Derby.logger = DataObjects::Logger.new(log_path, 0)

at_exit { DataObjects.logger.flush }

Spec::Runner.configure do |config|
  config.include(DataObjects::Spec::PendingHelpers)
end

module DerbySpecHelpers

  def insert(query, *args)
    result = @connection.create_command(query).execute_non_query(*args)
    result.insert_id
  end

  def exec(query, *args)
    @connection.create_command(query).execute_non_query(*args)
  end

  def select(query, types = nil, *args)
    begin
      command = @connection.create_command(query)
      command.set_types types unless types.nil?
      reader = command.execute_reader(*args)
      reader.next!
      yield reader if block_given?
    ensure
      reader.close if reader
    end
  end


  def setup_test_environment
    @connection = DataObjects::Connection.new("jdbc:derby:testdb;create=true")

    # Derby does not support DROP TABLE IF EXISTS
    begin
        @connection.create_command(<<-EOF).execute_non_query
          DROP TABLE invoices
        EOF
    rescue DerbyError
    end

    begin
        @connection.create_command(<<-EOF).execute_non_query
            DROP TABLE users
        EOF
    rescue DerbyError
    end

    begin
        @connection.create_command(<<-EOF).execute_non_query
          DROP TABLE widgets
        EOF
    rescue DerbyError
    end

    @connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id                INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        name              VARCHAR(200) default 'Billy',
        fired_at          TIMESTAMP
      )
    EOF

    @connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE invoices (
        id                INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        invoice_number    VARCHAR(50) NOT NULL
      )
    EOF

    @connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE widgets (
        id                INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        code              CHAR(8) DEFAULT 'A14',
        name              VARCHAR(200) DEFAULT 'Super Widget',
        shelf_location    VARCHAR(50),
        description       LONG VARCHAR,
        image_data        BLOB,
        ad_description    LONG VARCHAR,
        ad_image          BLOB,
        whitepaper_text   LONG VARCHAR,
        cad_drawing       BLOB,
        flags             SMALLINT DEFAULT 0,
        number_in_stock   SMALLINT DEFAULT 500,
        number_sold       INTEGER DEFAULT 0,
        super_number      BIGINT DEFAULT 9223372036854775807
      )
    EOF

    # REMOVED:
    # weight            FLOAT DEFAULT 1.23,
    # cost1             REAL DEFAULT 10.23,
    # cost2             DECIMAL DEFAULT 50.23,
    # release_date      DATE DEFAULT '2008-02-14',
    # release_datetime  DATETIME, DEFAULT '2008-02-14 00:31:12',
    # release_timestamp TIMESTAMP, DEFAULT '2008-02-14 00:31:31'
    #
    # XXX: HSQLDB has no ENUM
    # status` enum('active','out of stock') NOT NULL default 'active'

    1.upto(16) do |n|
      @connection.create_command(<<-EOF).execute_non_query
        INSERT INTO widgets(
          code,
          name,
          shelf_location,
          description,
          ad_description,
          whitepaper_text,
          super_number)
        VALUES (
          'W#{n.to_s.rjust(7,"0")}',
          'Widget #{n}',
          'A14',
          'This is a description',
          'Buy this product now!',
          'Utilizing blah blah blah',
          1234)
      EOF

      # Removed
      #           image_data,
      #           ad_image,
      #           cad_drawing,
      # XXX: figure out how to insert BLOBS
    end

  end
end
