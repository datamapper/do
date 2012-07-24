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
require 'do_openedge'

DataObjects::Openedge.logger = DataObjects::Logger.new(STDOUT, :off)
at_exit { DataObjects.logger.flush }


CONFIG              = OpenStruct.new
CONFIG.scheme       = 'openedge'
CONFIG.driver       = 'openedge'
CONFIG.jdbc_driver  = DataObjects::Openedge.const_get('JDBC_DRIVER') rescue nil
CONFIG.user         = ENV['DO_OPENEDGE_USER'] || 'test'
CONFIG.pass         = ENV['DO_OPENEDGE_PASS'] || ''
CONFIG.host         = ENV['DO_OPENEDGE_HOST'] || '192.168.1.241'
CONFIG.port         = ENV['DO_OPENEDGE_PORT'] || '13370'
CONFIG.database     = ENV['DO_OPENEDGE_DATABASE'] || 'test'
# Result of this query must be a value of "1":
CONFIG.testsql      = "SELECT SIGN(1) FROM SYSPROGRESS.SYSCALCTABLE"
CONFIG.uri          = ENV["DO_OPENEDGE_SPEC_URI"] ||"#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}/#{CONFIG.database}"
CONFIG.jdbc_uri     = "jdbc:openedge://#{CONFIG.host}:#{CONFIG.port}/#{CONFIG.database}?user=#{CONFIG.user}&password=#{CONFIG.pass}"

module DataObjectsSpecHelpers

  TABLE_NOT_FOUND_CODE = -20005
  SEQUENCE_NOT_FOUND_CODE = -210051
  SEQUENCE_NOT_VALID_CODE = -20170
  TRIGGER_NOT_FOUND_CODE = -20147

  def drop_table_seq_and_trig(conn, table_name, catalog="pub")
    table_name = "#{catalog}.#{table_name}" if catalog && !catalog.empty?
    begin
      conn.create_command("DROP TABLE #{table_name}").execute_non_query
    rescue DataObjects::SQLError => e
      # OpenEdge does not support DROP TABLE IF EXISTS
      raise e unless e.code == TABLE_NOT_FOUND_CODE
    end

    begin
      conn.create_command("DROP SEQUENCE #{table_name}_id_seq").execute_non_query
    rescue DataObjects::SQLError => e
      raise e unless [SEQUENCE_NOT_FOUND_CODE, SEQUENCE_NOT_VALID_CODE].include?(e.code)
    end

    begin
      conn.create_command("DROP TRIGGER #{table_name}_trigger").execute_non_query
    rescue DataObjects::SQLError => e
      raise e unless e.code == TRIGGER_NOT_FOUND_CODE
    end
  end

  def create_seq_and_trigger(conn, table_name, catalog="pub")
    table_name = "#{catalog}.#{table_name}" if catalog && !catalog.empty?
    conn.create_command(<<-EOF).execute_non_query
      CREATE SEQUENCE #{table_name}_id_seq
      START WITH 0,
      INCREMENT BY 1,
      NOCYCLE
    EOF

    # Not opening up sequence permissions causes weird errors.
    # See ProKB P131308, P10499 for examples
    # Also, GRANT ALL doesn't work on sequences; it raises error 12666 "invalid sequence name"
    # (probably because some table operations don't apply to sequences)
    %w{SELECT UPDATE}.each do |perm|
      conn.create_command(<<-EOF).execute_non_query
        GRANT #{perm} ON SEQUENCE #{table_name}_id_seq TO PUBLIC
      EOF
    end

    conn.create_command(<<-EOF).execute_non_query
      CREATE TRIGGER #{table_name}_trigger
      BEFORE INSERT ON #{table_name}
      REFERENCING NEWROW
      FOR EACH ROW
      IMPORT
      import java.sql.*;
      BEGIN
      Long current_id = (Long)NEWROW.getValue(1, BIGINT);
      if (current_id == -1) {
        SQLCursor next_id_query = new SQLCursor("SELECT TOP 1 #{table_name}_id_seq.NEXTVAL FROM SYSPROGRESS.SYSCALCTABLE");
        next_id_query.open();
        next_id_query.fetch();
        Long next_id = (Long)next_id_query.getValue(1,BIGINT);
        next_id_query.close();
        NEWROW.setValue(1, next_id);
      }
      END
    EOF
  end

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    drop_table_seq_and_trig(conn, "invoices")
    drop_table_seq_and_trig(conn, "users")
    drop_table_seq_and_trig(conn, "widgets")

    # Users
    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id                BIGINT PRIMARY KEY DEFAULT -1,
        name              VARCHAR(200) default 'Billy',
        fired_at          TIMESTAMP
      )
    EOF
    create_seq_and_trigger(conn, "users", "")

    # Invoices
    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE invoices (
        id                BIGINT PRIMARY KEY DEFAULT -1,
        invoice_number    VARCHAR(50) NOT NULL
      )
    EOF
    create_seq_and_trigger(conn, "invoices", "")

    # Widgets
    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE widgets (
        id                BIGINT PRIMARY KEY DEFAULT -1,
        code              CHAR(8) DEFAULT 'A14',
        name              VARCHAR(200) DEFAULT 'Super Widget',
        shelf_location    VARCHAR(4000),
        description       VARCHAR(4000),
        image_data        BLOB,
        ad_description    VARCHAR(4000),
        ad_image          BLOB,
        whitepaper_text   CLOB,
        class_name        VARCHAR(4000),
        cad_drawing       BLOB,
        flags             BIT DEFAULT 0,
        number_in_stock   SMALLINT DEFAULT 500,
        number_sold       INTEGER DEFAULT 0,
        super_number      BIGINT DEFAULT 9223372036854775807,
        weight            FLOAT DEFAULT 1.23,
        cost1             REAL DEFAULT 10.23,
        cost2             DECIMAL DEFAULT 50.23,
        release_date      DATE DEFAULT '2008-02-14',
        release_datetime  TIMESTAMP DEFAULT '2008-02-14 00:31:12',
        release_timestamp TIMESTAMP DEFAULT '2008-02-14 00:31:31'
      )
    EOF
    create_seq_and_trigger(conn, "widgets", "")

    # XXX: OpenEdge has no ENUM
    # status` enum('active','out of stock') NOT NULL default 'active'

    command = conn.create_command(<<-EOF)
      INSERT INTO widgets(
        code,
        name,
        shelf_location,
        description,
        ad_description,
        class_name,
        super_number,
        weight,
        release_datetime,
        release_timestamp)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    EOF

    1.upto(16) do |n|
      command.execute_non_query(
        "W#{n.to_s.rjust(7,'0')}",
        "Widget #{n}",
        'A14',
        'This is a description',
        'Buy this product now!',
        'String',
        1234,
        13.4,
        Time.local(2008,2,14,0,31,12),
        Time.local(2008,2,14,0,31,12))
    end

    # These updates are done separately from the initial inserts because the
    # BLOB/CLOB fields seem to stop the before insert trigger from running!
    1.upto(16) do |i|
      command = conn.create_command(<<-EOF)
        update widgets set
        image_data = ?,
        ad_image = ?,
        whitepaper_text = ?,
        cad_drawing = ?
        where id = #{i}
      EOF
      command.execute_non_query(
        ::Extlib::ByteArray.new('IMAGE DATA'),
        ::Extlib::ByteArray.new('AD IMAGE DATA'),
        '1234567890'*500,
        ::Extlib::ByteArray.new("CAD \001 \000 DRAWING")
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
  end
end

RSpec.configure do |config|
  config.include(DataObjectsSpecHelpers)
  config.include(DataObjects::Spec::PendingHelpers)
end
