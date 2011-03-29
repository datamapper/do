$TESTING=true
JRUBY = RUBY_PLATFORM =~ /java/

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
(['data_objects'] << ('do_jdbc' if JRUBY)).compact.each do |lib|
  lib_path = "#{repo_root}/#{lib}/lib"
  $LOAD_PATH.unshift(lib_path) if File.directory?(lib_path) && !$LOAD_PATH.include?(lib_path)
end

require 'data_objects'
require 'data_objects/spec/setup'
require 'data_objects/spec/lib/pending_helpers'
require 'do_oracle'

DataObjects::Oracle.logger = DataObjects::Logger.new(STDOUT, :off)
at_exit { DataObjects.logger.flush }


# Set default time zone in MRI if not set in environment
# as otherwise wrong time zone is set for database connection
ENV['TZ'] ||= 'EET' unless JRUBY

CONFIG = OpenStruct.new
CONFIG.scheme   = 'oracle'
CONFIG.user     = ENV['DO_ORACLE_USER'] || 'do_test'
CONFIG.pass     = ENV['DO_ORACLE_PASS'] || 'do_test'
CONFIG.host     = ENV['DO_ORACLE_HOST'] || 'localhost'
CONFIG.port     = ENV['DO_ORACLE_PORT'] || '1521'
CONFIG.database = ENV['DO_ORACLE_DATABASE'] || '/orcl'

CONFIG.uri = ENV["DO_ORACLE_SPEC_URI"] ||"#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}"
CONFIG.sleep = "BEGIN SYS.DBMS_LOCK.sleep(seconds => 1); END;"
CONFIG.testsql = "SELECT 1 FROM dual"

module DataObjectsSpecHelpers

  def drop_table_and_seq(conn, table_name)
    begin
      conn.create_command("DROP TABLE #{table_name}").execute_non_query
    rescue StandardError => error
      raise unless error.to_s =~ /ORA-00942/
    end
    begin
      conn.create_command("DROP SEQUENCE #{table_name}_seq").execute_non_query
    rescue StandardError => error
      raise unless error.to_s =~ /ORA-02289/
    end
  end

  def create_seq_and_trigger(conn, table_name)
    conn.create_command("CREATE SEQUENCE #{table_name}_seq").execute_non_query
    conn.create_command(<<-EOF).execute_non_query
    CREATE OR REPLACE TRIGGER #{table_name}_pkt
    BEFORE INSERT ON #{table_name} FOR EACH ROW
    BEGIN
      IF inserting THEN
        IF :new.id IS NULL THEN
          SELECT #{table_name}_seq.NEXTVAL INTO :new.id FROM dual;
        END IF;
      END IF;
    END;
    EOF
  end

  def setup_test_environment(force_setup = false)
    # setup test environment just once
    return if $test_environment_setup_done && !force_setup
    puts "Setting up test environment"

    conn = DataObjects::Connection.new(CONFIG.uri)

    drop_table_and_seq(conn, "invoices")
    drop_table_and_seq(conn, "users")
    drop_table_and_seq(conn, "widgets")

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id NUMBER(38,0) PRIMARY KEY NOT NULL,
        name VARCHAR(200) default 'Billy',
        fired_at timestamp
      )
    EOF
    create_seq_and_trigger(conn, "users")

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE invoices (
        id NUMBER(38,0) PRIMARY KEY NOT NULL,
        invoice_number VARCHAR2(50) NOT NULL
      )
    EOF
    create_seq_and_trigger(conn, "invoices")

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE widgets (
        id NUMBER(38,0) PRIMARY KEY NOT NULL,
        code CHAR(8) DEFAULT 'A14',
        name VARCHAR2(200) DEFAULT 'Super Widget',
        shelf_location VARCHAR2(4000),
        description VARCHAR2(4000),
        image_data BLOB,
        ad_description VARCHAR2(4000),
        ad_image BLOB,
        whitepaper_text CLOB,
        class_name VARCHAR2(4000),
        cad_drawing BLOB,
        flags NUMBER(1) default 0,
        number_in_stock NUMBER(38,0) DEFAULT 500,
        number_sold NUMBER(38,0) DEFAULT 0,
        super_number NUMBER(38,0) DEFAULT 9223372036854775807,
        weight BINARY_FLOAT DEFAULT 1.23,
        cost1 BINARY_DOUBLE DEFAULT 10.23,
        cost2 NUMBER(8,2) DEFAULT 50.23,
        release_date DATE DEFAULT '2008-02-14',
        release_datetime DATE DEFAULT '2008-02-14 00:31:12',
        release_timestamp TIMESTAMP WITH TIME ZONE DEFAULT '2008-02-14 00:31:12 #{"%+03d" % (Time.local(2008,2,14,0,31,12).utc_offset/3600)}:00'
      )
    EOF
    create_seq_and_trigger(conn, "widgets")

    command = conn.create_command(<<-EOF)
      insert into widgets(code, name, shelf_location, description, image_data,
        ad_description, ad_image, whitepaper_text,
        class_name, cad_drawing, super_number, weight
        ,release_datetime, release_timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
        ,?, ?)
    EOF

    1.upto(16) do |n|
      # conn.create_command(<<-EOF).execute_non_query
      #   insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number, weight) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'String', 'CAD \\001 \\000 DRAWING', 1234, 13.4);
      # EOF
      # conn.create_command(<<-EOF).execute_non_query
      #   insert into widgets(code, name, shelf_location, description, ad_description, whitepaper_text, super_number, weight) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'Buy this product now!', 'String', 1234, 13.4)
      # EOF
      command.execute_non_query(
        "W#{n.to_s.rjust(7,"0")}", "Widget #{n}", 'A14', 'This is a description', ::Extlib::ByteArray.new('IMAGE DATA'),
        'Buy this product now!', ::Extlib::ByteArray.new('AD IMAGE DATA'), '1234567890'*500,
        'String', ::Extlib::ByteArray.new("CAD \001 \000 DRAWING"), 1234, 13.4,
        Time.local(2008,2,14,0,31,12), Time.local(2008,2,14,0,31,12)
      )
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
    $test_environment_setup_done = true
  end

end

RSpec.configure do |config|
  config.include(DataObjectsSpecHelpers)
  config.include(DataObjects::Spec::PendingHelpers)
end
