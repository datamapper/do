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
require 'do_h2'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::H2.logger = DataObjects::Logger.new(log_path, :debug)

at_exit { DataObjects.logger.flush }

Spec::Runner.configure do |config|
  config.include(DataObjects::Spec::PendingHelpers)
end

CONFIG = OpenStruct.new
# CONFIG.scheme   = 'h2'
# CONFIG.user     = ENV['DO_H2_USER'] || 'h2'
# CONFIG.pass     = ENV['DO_H2_PASS'] || ''
# CONFIG.host     = ENV['DO_H2_HOST'] || ''
# CONFIG.port     = ENV['DO_H2_PORT'] || ''
# CONFIG.database = ENV['DO_H2_DATABASE'] || "#{File.expand_path(File.dirname(__FILE__))}/testdb"

CONFIG.uri = ENV["DO_H2_SPEC_URI"] || "jdbc:h2:mem"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS invoices
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS users
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS widgets
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id                INTEGER IDENTITY,
        name              VARCHAR(200) default 'Billy' NULL,
        fired_at          TIMESTAMP
      )
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE invoices (
        id                INTEGER IDENTITY,
        invoice_number    VARCHAR(50) NOT NULL
      )
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE widgets (
        id                INTEGER IDENTITY,
        code              CHAR(8) DEFAULT 'A14' NULL,
        name              VARCHAR(200) DEFAULT 'Super Widget' NULL,
        shelf_location    VARCHAR NULL,
        description       LONGVARCHAR NULL,
        image_data        VARBINARY NULL,
        ad_description    LONGVARCHAR NULL,
        ad_image          VARBINARY NULL,
        whitepaper_text   LONGVARCHAR NULL,
        cad_drawing       LONGVARBINARY NULL,
        flags             TINYINT DEFAULT 0,
        number_in_stock   SMALLINT DEFAULT 500,
        number_sold       INTEGER DEFAULT 0,
        super_number      BIGINT DEFAULT 9223372036854775807,
        weight            FLOAT DEFAULT 1.23,
        cost1             REAL DEFAULT 10.23,
        cost2             DECIMAL DEFAULT 50.23,
        release_date      DATE DEFAULT '2008-02-14',
        release_datetime  DATETIME DEFAULT '2008-02-14 00:31:12',
        release_timestamp TIMESTAMP DEFAULT '2008-02-14 00:31:31'
      )
    EOF
    # XXX: H2 has no ENUM
    # status` enum('active','out of stock') NOT NULL default 'active'

    1.upto(16) do |n|
      conn.create_command(<<-EOF).execute_non_query
        INSERT INTO widgets(
          code,
          name,
          shelf_location,
          description,
          image_data,
          ad_description,
          ad_image,
          whitepaper_text,
          cad_drawing,
          super_number,
          weight)
        VALUES (
          'W#{n.to_s.rjust(7,"0")}',
          'Widget #{n}',
          'A14',
          'This is a description',
          '4f3d4331434343434331',
          'Buy this product now!',
          '4f3d4331434343434331',
          'Utilizing blah blah blah',
          '4f3d4331434343434331',
          1234,
          13.4);
      EOF

      ## TODO: change the hexadecimal examples

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
