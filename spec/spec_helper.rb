$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'do_jdbc'

# Hack to load the HSQLDB Driver
require 'hsqldb'
include Java
import 'org.hsqldb.jdbcDriver'

Spec::Runner.configure do |config|
  # Use Mocha rather than RSpec Mocks
  config.mock_with :mocha
end

module JdbcSpecHelpers

  # Copied wholesale from sqlite3 spec_helper.rb
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
      yield reader
    ensure
      reader.close if reader
    end
  end


  def setup_test_environment
    @connection = DataObjects::Connection.new("jdbc:hsqldb:mem")

    @connection.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `invoices`
    EOF

    @connection.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `users`
    EOF

    @connection.create_command(<<-EOF).execute_non_query
      DROP TABLE IF EXISTS `widgets`
    EOF

    @connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE `users` (
        `id` int(11) NOT NULL auto_increment,
        `name` varchar(200) default 'Billy' NULL,
        `fired_at` timestamp,
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    @connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE `invoices` (
        `id` int(11) NOT NULL auto_increment,
        `invoice_number` varchar(50) NOT NULL,
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    @connection.create_command(<<-EOF).execute_non_query
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
        `flags` tinyint(1) default 0,
        `number_in_stock` smallint default 500,
        `number_sold` mediumint default 0,
        `super_number` bigint default 9223372036854775807,
        `weight` float default 1.23,
        `cost1` double(8,2) default 10.23,
        `cost2` decimal(8,2) default 50.23,
        `release_date` date default '2008-02-14',
        `release_datetime` datetime default '2008-02-14 00:31:12',
        `release_timestamp` timestamp default '2008-02-14 00:31:31',
        `status` enum('active','out of stock') NOT NULL default 'active',
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
    EOF

    1.upto(16) do |n|
      @connection.create_command(<<-EOF).execute_non_query
        insert into widgets(code, name, shelf_location, description, image_data, ad_description, ad_image, whitepaper_text, cad_drawing, super_number) VALUES ('W#{n.to_s.rjust(7,"0")}', 'Widget #{n}', 'A14', 'This is a description', 'IMAGE DATA', 'Buy this product now!', 'AD IMAGE DATA', 'Utilizing blah blah blah', 'CAD DRAWING', 1234);
      EOF
    end

  end
end
