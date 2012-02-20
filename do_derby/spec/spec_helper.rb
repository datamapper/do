$TESTING=true
JRUBY = true

require 'rubygems'
require 'rspec'
require 'date'
require 'ostruct'
require 'fileutils'

driver_lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(driver_lib) unless $LOAD_PATH.include?(driver_lib)

# Prepend data_objects/do_jdbc in the repository to the load path.
# DO NOT USE installed gems, except when running the specs from gem.
repo_root = File.expand_path('../../..', __FILE__)
['data_objects', 'do_jdbc'].each do |lib|
  lib_path = "#{repo_root}/#{lib}/lib"
  $LOAD_PATH.unshift(lib_path) if File.directory?(lib_path) && !$LOAD_PATH.include?(lib_path)
end

require 'data_objects'
require 'data_objects/spec/setup'
require 'data_objects/spec/lib/pending_helpers'
require 'do_derby'

DataObjects::Derby.logger = DataObjects::Logger.new(STDOUT, :off)
at_exit { DataObjects.logger.flush }


CONFIG              = OpenStruct.new
CONFIG.uri          = ENV["DO_DERBY_SPEC_URI"] || "jdbc:derby:testdb;create=true"
CONFIG.driver       = 'derby'
CONFIG.jdbc_driver  = DataObjects::Derby::JDBC_DRIVER
CONFIG.testsql      = "SELECT 1 FROM SYSIBM.SYSDUMMY1"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    # Derby does not support DROP TABLE IF EXISTS
    begin
        conn.create_command(<<-EOF).execute_non_query
          DROP TABLE invoices
        EOF
    rescue DataObjects::SQLError
    end

    begin
        conn.create_command(<<-EOF).execute_non_query
            DROP TABLE users
        EOF
    rescue DataObjects::SQLError
    end

    begin
        conn.create_command(<<-EOF).execute_non_query
          DROP TABLE widgets
        EOF
    rescue DataObjects::SQLError
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
    end

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

    conn.create_command(<<-EOF).execute_non_query
      update widgets set flags = NULL where id = 4
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set cost1 = NULL where id = 5
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set cost2 = NULL where id = 6
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_date = NULL where id = 7
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_datetime = NULL where id = 8
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_timestamp = NULL where id = 9
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_datetime = '2008-07-14 00:31:12' where id = 10
    EOF

    conn.close

  end
end

RSpec.configure do |config|
  config.include(DataObjectsSpecHelpers)
  config.include(DataObjects::Spec::PendingHelpers)
end
