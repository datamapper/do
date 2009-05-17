$TESTING=true
JRUBY = RUBY_PLATFORM =~ /java/

require 'rubygems'

gem 'rspec', '>1.1.12'
require 'spec'

require 'date'
require 'ostruct'
require 'pathname'
require 'fileutils'

gem 'ruby-oci8', '>=2.0.2'
require 'oci8'

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
require 'do_oracle'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::Oracle.logger = DataObjects::Logger.new(log_path, :debug)

at_exit { DataObjects.logger.flush }

Spec::Runner.configure do |config|
  config.include(DataObjects::Spec::PendingHelpers)
end

CONFIG = OpenStruct.new
CONFIG.scheme   = 'oracle'
CONFIG.user     = ENV['DO_ORACLE_USER'] || 'do_test'
CONFIG.pass     = ENV['DO_ORACLE_PASS'] || 'do_test'
CONFIG.host     = ENV['DO_ORACLE_HOST'] || 'localhost'
CONFIG.port     = ENV['DO_ORACLE_PORT'] || '1521'
CONFIG.database = ENV['DO_ORACLE_DATABASE'] || '/orcl'

CONFIG.uri = ENV["DO_ORACLE_SPEC_URI"] ||"#{CONFIG.scheme}://#{CONFIG.user}:#{CONFIG.pass}@#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}"
CONFIG.sleep = "BEGIN DBMS_LOCK.sleep(seconds => 1); END;"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    conn.create_command(<<-EOF).execute_non_query rescue nil
      DROP TABLE invoices
    EOF
    conn.create_command(<<-EOF).execute_non_query rescue nil
      DROP SEQUENCE invoices_seq
    EOF

    conn.create_command(<<-EOF).execute_non_query rescue nil
      DROP TABLE users
    EOF
    conn.create_command(<<-EOF).execute_non_query rescue nil
      DROP SEQUENCE users_seq
    EOF

    conn.create_command(<<-EOF).execute_non_query rescue nil
      DROP TABLE widgets
    EOF
    conn.create_command(<<-EOF).execute_non_query rescue nil
      DROP SEQUENCE widgets_seq
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id NUMBER(38,0) PRIMARY KEY NOT NULL,
        name VARCHAR(200) default 'Billy',
        fired_at timestamp
      )
    EOF
    conn.create_command(<<-EOF).execute_non_query
      CREATE SEQUENCE users_seq
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE invoices (
        id NUMBER(38,0) PRIMARY KEY NOT NULL,
        invoice_number VARCHAR2(50) NOT NULL
      )
    EOF
    conn.create_command(<<-EOF).execute_non_query
      CREATE SEQUENCE invoices_seq
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE widgets (
        id NUMBER(38,0) PRIMARY KEY NOT NULL,
        code CHAR(8) DEFAULT 'A14',
        name VARCHAR2(200) DEFAULT 'Super Widget',
        shelf_location VARCHAR2(4000),
        description CLOB,
        image_data BLOB,
        ad_description CLOB,
        ad_image BLOB,
        whitepaper_text CLOB,
        cad_drawing BLOB,
        flags NUMBER(1) default 0,
        number_in_stock NUMBER(38,0) DEFAULT 500,
        number_sold NUMBER(38,0) DEFAULT 0,
        super_number NUMBER(38,0) DEFAULT 9223372036854775807,
        weight FLOAT DEFAULT 1.23,
        cost1 FLOAT DEFAULT 10.23,
        cost2 NUMBER(8,2) DEFAULT 50.23,
        release_date DATE DEFAULT '2008-02-14',
        release_datetime TIMESTAMP DEFAULT '2008-02-14 00:31:12',
        release_timestamp TIMESTAMP WITH TIME ZONE DEFAULT '2008-02-14 00:31:31'
      )
    EOF
    conn.create_command(<<-EOF).execute_non_query
      CREATE SEQUENCE widgets_seq
    EOF

    1.upto(16) do |n|
      # conn.create_command(<<-EOF).execute_non_query
      #   insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number, weight) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'String', 'CAD \\001 \\000 DRAWING', 1234, 13.4);
      # EOF
      conn.create_command(<<-EOF).execute_non_query
        insert into widgets(id, code, name, shelf_location, description, ad_description, whitepaper_text, super_number, weight) VALUES (widgets_seq.nextval, 'W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'Buy this product now!', 'String', 1234, 13.4)
      EOF
    end

    conn.create_command(<<-EOF).execute_non_query
      update widgets set flags = 1 where id = 2
    EOF

    conn.create_command(<<-EOF).execute_non_query
      update widgets set ad_description = NULL where id = 3
    EOF

    conn.close

  end

end
