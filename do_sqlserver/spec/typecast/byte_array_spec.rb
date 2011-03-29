# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/byte_array_spec'

describe 'DataObjects::SqlServer with ByteArray' do
  # it_should_behave_like 'supporting ByteArray'
  #
  # ByteArray is not yet supported on JRuby:
  #
  # Like Postgres, SQL Server doesn't typecast bytea type to integer, decimal,
  # etc. In other words,
  #   @connection.create_command("SELECT id FROM widgets WHERE id = ?").execute_reader(::Extlib::ByteArray.new("2"))
  # results in the equivalent to the following query being executed:
  #   SELECT id FROM widgets WHERE id = 0x32
  # BUT 0x32 as a parameter = (decimal) 50
  # NOT the ASCII char for '2'.
  #
  # Other drivers (Postgres) override #setPreparedStatementParam in their
  # DriverDefinition implementations and use ps.getParameterMetadata() to let
  # the JDBC driver handle the casting.
  #
  # Unfortunately, we can't rely on ps.getParameterMetadata() because of the
  # following bug in jTDS:
  # https://sourceforge.net/tracker/?func=detail&aid=2220192&group_id=33291&atid=407762
  #  getParameterClassName(idx) => java.lang.Object
  #  getParameterTypeName(idx)  => null
  #  getParameterType(idx)      => 0 (NULL)
  #
  # Without this information we don't know what we should be casting to!
end
