$TESTING=true

require 'rubygems'

gem 'rspec', '>=1.1.3'
require 'spec'

require 'date'
require 'pathname'
require 'fileutils'
require 'bigdecimal'

# put data_objects from repository in the load path
# DO NOT USE installed gem of data_objects!
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data_objects', 'lib'))
require 'data_objects'

# put the pre-compiled extension in the path to be found
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'do_postgres'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::Postgres.logger = DataObjects::Logger.new(log_path, 0)

module PostgresSpecHelpers

  def ensure_users_table_and_return_connection
    connection = DataObjects::Connection.new("postgres://localhost/do_test")
    connection.create_command("DROP TABLE users").execute_non_query rescue nil
    connection.create_command("DROP TABLE companies").execute_non_query rescue nil
    connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE users (
        id serial NOT NULL,
        "name" text,
        registered boolean DEFAULT false,
        money double precision DEFAULT 1908.56,
        created_on date DEFAULT ('now'::text)::date,
        created_at timestamp without time zone DEFAULT now(),
--        born_at time without time zone DEFAULT now(),
        fired_at timestamp with time zone DEFAULT now(),
        company_id integer DEFAULT 1
      )
      WITH (OIDS=FALSE);
    EOF

    connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE companies (
        id serial NOT NULL,
        "name" character varying
      )
      WITH (OIDS=FALSE);
    EOF

    return connection
  end

  def insert(query, *args)
    result = @connection.create_command(query[/\) RETURNING.*/i] ? query : "#{query} RETURNING id").execute_non_query(*args)
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
      reader.close
    end
  end
end
