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
require 'data_objects/spec/lib/ssl'
require 'data_objects/spec/lib/pending_helpers'
require 'do_mysql'

DataObjects::Mysql.logger = DataObjects::Logger.new(STDOUT, :off)
at_exit { DataObjects.logger.flush }


CONFIG = OpenStruct.new
CONFIG.scheme   = 'mysql'
CONFIG.user     = ENV['DO_MYSQL_USER'] || 'root'
CONFIG.pass     = ENV['DO_MYSQL_PASS'] || ''
CONFIG.user_info = unless CONFIG.user == 'root' && CONFIG.pass.empty?
  "#{CONFIG.user}:#{CONFIG.pass}@"
else
  ''
end
CONFIG.host     = ENV['DO_MYSQL_HOST'] || 'localhost'
CONFIG.port     = ENV['DO_MYSQL_PORT'] || '3306'
CONFIG.database = ENV['DO_MYSQL_DATABASE'] || '/do_test'
CONFIG.ssl      = SSLHelpers.query(:ca_cert, :client_cert, :client_key)

CONFIG.driver       = 'mysql'
CONFIG.jdbc_driver  = DataObjects::Mysql.const_get('JDBC_DRIVER') rescue nil
CONFIG.uri          = ENV["DO_MYSQL_SPEC_URI"] || "#{CONFIG.scheme}://#{CONFIG.user_info}#{CONFIG.host}:#{CONFIG.port}#{CONFIG.database}?zeroDateTimeBehavior=convertToNull"
CONFIG.jdbc_uri     = "jdbc:#{CONFIG.uri}"
CONFIG.sleep        = "SELECT sleep(1)"

module DataObjectsSpecHelpers

  def setup_test_environment
    conn = DataObjects::Connection.new(CONFIG.uri)

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `invoices`
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `users`
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `stuff`
    EOF

    conn.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `widgets`
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE `users` (
        `id` int(11) NOT NULL auto_increment,
        `name` varchar(200) default 'Billy' NULL,
        `fired_at` timestamp,
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE `invoices` (
        `invoice_number` varchar(50) NOT NULL,
        PRIMARY KEY  (`invoice_number`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE `stuff` (
        `id` bigint NOT NULL auto_increment,
        `value` varchar(50) NULL,
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    conn.create_command(<<-EOF).execute_non_query
      CREATE TABLE `widgets` (
        `id` int(11) NOT NULL auto_increment,
        `code` char(8) default 'A14' NULL,
        `name` varchar(200) default 'Super Widget' NULL,
        `shelf_location` tinytext NULL,
        `description` text NULL,
        `image_data` blob NULL,
        `ad_description` mediumtext NULL,
        `ad_image` mediumblob NULL,
        `whitepaper_text` longtext NULL,
        `cad_drawing` longblob NULL,
        `flags` boolean default false,
        `number_in_stock` smallint default 500,
        `number_sold` mediumint default 0,
        `super_number` bigint default 9223372036854775807,
        `weight` float default 1.23,
        `cost1` double default 10.23,
        `cost2` decimal(8,2) default 50.23,
        `release_date` date default '2008-02-14',
        `release_datetime` datetime default '2008-02-14 00:31:12',
        `release_timestamp` timestamp NULL default '2008-02-14 00:31:31',
        `status` enum('active','out of stock') NOT NULL default 'active',
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    1.upto(16) do |n|
      conn.create_command(<<-EOF).execute_non_query
        insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number, weight) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'String', 'CAD \001 \000 DRAWING', 1234, 13.4);
      EOF
    end

    conn.create_command(<<-EOF).execute_non_query
      update widgets set flags = true where id = 2
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

  def self.test_environment_ssl_config
    ssl_config = SSLHelpers::CONFIG

    message =  "\nYou can configure MySQL via my.cnf with the following options in [mysqld]:\n"
    message << "ssl_ca=#{ssl_config.ca_cert}\n"
    message << "ssl_cert=#{ssl_config.server_cert}\n"
    message << "ssl_key=#{ssl_config.server_key}\n"
    message << "ssl_cipher=#{ssl_config.cipher}\n"

    message << "\nOr you can use the following command line options:\n"
    message << "--ssl-ca #{ssl_config.ca_cert} "
    message << "--ssl-cert #{ssl_config.server_cert} "
    message << "--ssl-key #{ssl_config.server_key} "
    message << "--ssl-cipher #{ssl_config.cipher} "
    message
  end

  def self.test_environment_ssl_config_errors
    conn = DataObjects::Connection.new(CONFIG.uri)

    ssl_variables = conn.create_command(<<-EOF).execute_reader
      SHOW VARIABLES LIKE '%ssl%'
    EOF

    ssl_config = SSLHelpers::CONFIG
    current_config = { }

    while ssl_variables.next!
      variable, value = ssl_variables.values
      current_config[variable.intern] = value
    end

    errors = []

    if current_config[:have_ssl] == 'NO'
      errors << "SSL was not compiled"
    end

    if current_config[:have_ssl] == 'DISABLED'
      errors << "SSL was not enabled"
    end

    if current_config[:ssl_ca] != ssl_config.ca_cert
      errors << "The CA certificate is not configured (it was set to '#{current_config[:ssl_ca]}')"
    end

    if current_config[:ssl_cert] != ssl_config.server_cert
      errors << "The server certificate is not configured (it was set to '#{current_config[:ssl_cert]}')"
    end

    if current_config[:ssl_key] != ssl_config.server_key
      errors << "The server key is not configured, (it was set to '#{current_config[:ssl_key]}')"
    end

    if current_config[:ssl_cipher] != ssl_config.cipher
      errors << "The cipher is not configured, (it was set to '#{current_config[:ssl_cipher]}')"
    end

    errors
  ensure
    conn.close if conn
  end

  def self.test_environment_supports_ssl?
    test_environment_ssl_config_errors.empty?
  end

end

RSpec.configure do |config|
  config.include(DataObjectsSpecHelpers)
  config.include(DataObjects::Spec::PendingHelpers)
end
