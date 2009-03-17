$TESTING=true

require 'rubygems'

gem 'rspec', '~>1.1.12'
require 'spec'

require 'date'
require 'ostruct'
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

DataObjects::Derby.logger = DataObjects::Logger.new(log_path, :debug)

at_exit { DataObjects.logger.flush }

Spec::Runner.configure do |config|
  config.include(DataObjects::Spec::PendingHelpers)
end

CONFIG = OpenStruct.new
# CONFIG.scheme   = 'derby'
# CONFIG.user     = ENV['DO_DERBY_USER'] || 'derby'
# CONFIG.pass     = ENV['DO_DERBY_PASS'] || ''
# CONFIG.host     = ENV['DO_DERBY_HOST'] || ''
# CONFIG.port     = ENV['DO_DERBY_PORT'] || ''
# CONFIG.database = ENV['DO_DERBY_DATABASE'] || "#{File.expand_path(File.dirname(__FILE__))}/testdb"

CONFIG.uri = ENV["DO_DERBY_SPEC_URI"] || "jdbc:derby:testdb;create=true"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    # Derby does not support DROP TABLE IF EXISTS
    begin
        conn.create_command(<<-EOF).execute_non_query
          DROP TABLE invoices
        EOF
    rescue DerbyError
    end

    begin
        conn.create_command(<<-EOF).execute_non_query
            DROP TABLE users
        EOF
    rescue DerbyError
    end

    begin
        conn.create_command(<<-EOF).execute_non_query
          DROP TABLE widgets
        EOF
    rescue DerbyError
    end

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id                INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        name              VARCHAR(200) default 'Billy',
        fired_at          TIMESTAMP
      )
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE invoices (
        id                INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        invoice_number    VARCHAR(50) NOT NULL
      )
    EOF

    # FIXME:
    # description, ad_description and whitepaper_text should be LONG VARCHAR and
    # not VARCHAR(500). However, the specs are failing with the following error
    # when the LONG VARCHAR type is used: Comparisons between 'LONG VARCHAR
    # (UCS_BASIC)' and 'LONG VARCHAR (UCS_BASIC)' are not supported. Types must
    # be comparable. String types must also have matching collation. If
    # collation does not match, a possible solution is to cast operands to force
    # them to the default collation (e.g. select tablename from sys.systables
    # where CAST(tablename as VARCHAR(128)) = 'T1')
    # Error Code: 30000
    # SQL State: 42818
    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE widgets (
        id                INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        code              CHAR(8) DEFAULT 'A14',
        name              VARCHAR(200) DEFAULT 'Super Widget',
        shelf_location    VARCHAR(50),
        description       VARCHAR(500),
        image_data        BLOB,
        ad_description    VARCHAR(500),
        ad_image          BLOB,
        whitepaper_text   VARCHAR(500),
        cad_drawing       BLOB,
        flags             SMALLINT DEFAULT 0,
        number_in_stock   SMALLINT DEFAULT 500,
        number_sold       INTEGER DEFAULT 0,
        super_number      BIGINT DEFAULT 9223372036854775807,
        weight            REAL DEFAULT 10.23,
        cost1             DOUBLE DEFAULT 10.23,
        cost2             DECIMAL(8,2) DEFAULT 50.23,
        release_date      DATE DEFAULT '2008-02-14',
        release_datetime  TIMESTAMP DEFAULT '2008-02-14 00:31:12',
        release_timestamp TIMESTAMP DEFAULT '2008-02-14 00:31:31'
      )
    EOF

    # XXX: Derby has no ENUM
    # status` enum('active','out of stock') NOT NULL default 'active'

    1.upto(16) do |n|
      conn.create_command(<<-EOF).execute_non_query
        INSERT INTO widgets(
          code,
          name,
          shelf_location,
          description,
          ad_description,
          whitepaper_text,
          super_number,
          weight)
        VALUES (
          'W#{n.to_s.rjust(7,"0")}',
          'Widget #{n}',
          'A14',
          'This is a description',
          'Buy this product now!',
          'String',
          1234,
          13.4)
      EOF

      # Removed
      #           image_data,
      #           ad_image,
      #           cad_drawing,
      # XXX: figure out how to insert BLOBS

      conn.create_command(<<-EOF).execute_non_query
        update widgets set flags = 1 where id = 2
      EOF

      conn.create_command(<<-EOF).execute_non_query
        update widgets set ad_description = NULL where id = 3
      EOF

      conn.close
    end

  end
end
