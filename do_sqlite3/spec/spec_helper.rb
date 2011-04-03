$TESTING=true
JRUBY = RUBY_PLATFORM =~ /java/

require 'rubygems'
require 'rspec'
require 'date'
require 'ostruct'
require 'fileutils'
require 'win32console' if RUBY_PLATFORM =~ /mingw|mswin/

driver_lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(driver_lib) unless $LOAD_PATH.include?(driver_lib)

# Prepend data_objects/do_jdbc in the repository to the load path.
# DO NOT USE installed gems, except when running the specs from gem.
repo_root = File.expand_path('../../..', __FILE__)
(['data_objects'] << ('do_jdbc' if JRUBY)).compact.each do |lib|
  lib_path = "#{repo_root}/#{lib}/lib"
  $LOAD_PATH.unshift(lib_path) if File.directory?(lib_path) && !$LOAD_PATH.include?(lib_path)
end

require 'data_objects'
require 'data_objects/spec/setup'
require 'data_objects/spec/lib/pending_helpers'
require 'do_sqlite3'


CONFIG              = OpenStruct.new
CONFIG.scheme       = 'sqlite3'
CONFIG.database     = ENV['DO_SQLITE3_DATABASE'] || ":memory:"
CONFIG.uri          = ENV["DO_SQLITE3_SPEC_URI"] || "#{CONFIG.scheme}:#{CONFIG.database}"
CONFIG.driver       = 'sqlite3'
CONFIG.jdbc_driver  = DataObjects::Sqlite3.const_get('JDBC_DRIVER') rescue nil
CONFIG.jdbc_uri     = CONFIG.uri.sub(/sqlite3/,"jdbc:sqlite")

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS "invoices"
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS "users"
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS "widgets"
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "users" (
        "id" SERIAL,
        "name" VARCHAR(200) default 'Billy' NULL,
        "fired_at" timestamp,
        PRIMARY KEY  ("id")
      );
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "invoices" (
        "invoice_number" varchar(50) NOT NULL,
        PRIMARY KEY  ("invoice_number")
      );
    EOF

    local_offset = Rational(Time.local(2008, 2, 14).utc_offset, 86400)
    t = DateTime.civil(2008, 2, 14, 00, 31, 12, local_offset)
    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE "widgets" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "code" char(8) default 'A14' NULL,
        "name" varchar(200) default 'Super Widget' NULL,
        "shelf_location" text NULL,
        "description" text NULL,
        "image_data" blob NULL,
        "ad_description" text NULL,
        "ad_image" blob NULL,
        "whitepaper_text" text NULL,
        "cad_drawing" blob,
        "flags" boolean default 'f',
        "number_in_stock" smallint default 500,
        "number_sold" integer default 0,
        "super_number" bigint default 9223372036854775807,
        "weight" float default 1.23,
        "cost1" double precision default 10.23,
        "cost2" decimal(8,2) default 50.23,
        "release_date" date default '2008-02-14',
        "release_datetime" timestamp default '#{t.to_s}',
        "release_timestamp" timestamp with time zone default '2008-02-14 00:31:31'
      );
    EOF

    1.upto(16) do |n|
      conn.create_command(<<-EOF).execute_non_query
        insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number, weight) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'String', X'434144200120002044524157494e47', 1234, 13.4);
      EOF
    end

    conn.create_command(<<-EOF).execute_non_query
      update widgets set flags = 't' where id = 2
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
