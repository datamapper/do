$TESTING=true
JRUBY = RUBY_PLATFORM =~ /java/

require 'rubygems'

gem 'rspec', '>1.1.12'
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

if JRUBY
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'do_jdbc', 'lib'))
  require 'do_jdbc'
end

# put the pre-compiled extension in the path to be found
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'do_sqlserver'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::SqlServer.logger = DataObjects::Logger.new(log_path, :debug)

at_exit { DataObjects.logger.flush }

Spec::Runner.configure do |config|
  config.include(DataObjects::Spec::PendingHelpers)
end

CONFIG = OpenStruct.new
CONFIG.scheme   = 'sqlserver'
CONFIG.user     = ENV['DO_SQLSERVER_USER'] || 'do_test'
CONFIG.pass     = ENV['DO_SQLSERVER_PASS'] || 'do_test'
CONFIG.host     = ENV['DO_SQLSERVER_HOST'] || '192.168.2.110'
CONFIG.port     = ENV['DO_SQLSERVER_PORT'] || '1433'
CONFIG.database = ENV['DO_SQLSERVER_DATABASE'] || '/do_test'
CONFIG.instance = ENV['DO_SQLSERVER_INSTANCE'] || 'SQLEXPRESS'

CONFIG.uri = ENV["DO_SQLSERVER_SPEC_URI"] ||"#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database};instance=#{CONFIG.instance}"
CONFIG.sleep = "WAITFOR DELAY '00:00:01'"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    conn.create_command(<<-EOF).execute_non_query
      IF OBJECT_ID('invoices') IS NOT NULL DROP TABLE invoices
    EOF

    conn.create_command(<<-EOF).execute_non_query
      IF OBJECT_ID('users') IS NOT NULL DROP TABLE users
    EOF

    conn.create_command(<<-EOF).execute_non_query
      IF OBJECT_ID('widgets') IS NOT NULL DROP TABLE widgets
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "users" (
        "id" int NOT NULL IDENTITY,
        "name" varchar(200) default 'Billy' NULL,
        "fired_at" timestamp,
        PRIMARY KEY ("id")
      );
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "invoices" (
        "id" int NOT NULL IDENTITY,
        "invoice_number" varchar(50) NOT NULL,
        PRIMARY KEY ("id")
      );
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "widgets" (
        "id" int NOT NULL IDENTITY,
        "code" char(8) default 'A14' NULL,
        "name" varchar(200) default 'Super Widget' NULL,
        "shelf_location" text NULL,
        "description" text NULL,
        "image_data" image NULL,
        "ad_description" varchar(8000) NULL,
        "ad_image" image NULL,
        "whitepaper_text" text NULL,
        "cad_drawing" image NULL,
        "flags" tinyint default 0,
        "number_in_stock" smallint default 500,
        "number_sold" int default 0,
        "super_number" bigint default 9223372036854775807,
        "weight" float default 1.23,
        "cost1" real default 10.23,
        "cost2" decimal(8,2) default 50.23,
        -- "release_date" date default '2008-02-14',
        "release_datetime" datetime default '2008-02-14 00:31:12',
        "release_timestamp" timestamp /* default '2008-02-14 00:31:31' */,
        -- "status" enum('active','out of stock') NOT NULL default 'active',
        PRIMARY KEY ("id")
      );
    EOF

    1.upto(16) do |n|
      conn.create_command(<<-EOF).execute_non_query
        insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number, weight)
        VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'String', 0x0102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F, 1234, 13.4);
      EOF
    end

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

    #conn.create_command(<<-EOF).execute_non_query
    #  update widgets set release_date = NULL where id = 7
    #EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_datetime = NULL where id = 8
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set release_timestamp = NULL where id = 9
    EOF

    conn.close

  end

end
