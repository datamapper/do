$TESTING=true
JRUBY = RUBY_PLATFORM =~ /java/

require 'rubygems'

gem 'rspec', '>=1.1.3'
require 'spec'

require 'date'
require 'ostruct'
require 'pathname'
require 'fileutils'
require 'bigdecimal'

# put data_objects from repository in the load path
# DO NOT USE installed gem of data_objects!
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data_objects', 'lib'))
require 'data_objects'

if JRUBY
  $:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'do_jdbc', 'lib'))
  require 'do_jdbc'
end

# put the pre-compiled extension in the path to be found
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'do_postgres'

log_path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'log', 'do.log'))
FileUtils.mkdir_p(File.dirname(log_path))

DataObjects::Postgres.logger = DataObjects::Logger.new(log_path, :debug)

POSTGRES = OpenStruct.new
POSTGRES.user = ENV['DO_PG_USER'] || 'postgres'
POSTGRES.pass = ENV['DO_PG_PASS'] || ''
POSTGRES.host = ENV['DO_PG_HOST'] || '127.0.0.1'
POSTGRES.hostname = ENV['DO_PG_HOSTNAME'] || 'localhost'
POSTGRES.port     = ENV['DO_PG_PORT'] || '5432'
POSTGRES.database = ENV['DO_PG_DATABASE'] || 'do_test'

DO_POSTGRES_SPEC_URI = Addressable::URI::parse(ENV["DO_PG_SPEC_URI"] ||
                    "postgres://#{POSTGRES.user}:#{POSTGRES.pass}@#{POSTGRES.hostname}:#{POSTGRES.port}/#{POSTGRES.database}")

module PostgresSpecHelpers

  def ensure_users_table_and_return_connection
    connection = DataObjects::Connection.new(DO_POSTGRES_SPEC_URI)
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
        born_at time without time zone DEFAULT now(),
        fired_at timestamp with time zone DEFAULT now(),
        amount numeric(10,2) DEFAULT 11.1,
        company_id integer DEFAULT 1
      )
      WITHOUT OIDS;
    EOF

    connection.create_command(<<-EOF).execute_non_query
      CREATE TABLE companies (
        id serial NOT NULL,
        "name" character varying
      )
      WITHOUT OIDS;
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
