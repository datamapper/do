# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/bigdecimal_spec'

# Sqlite3 doesn't support decimals natively, so autocasting is not available:
# http://www.sqlite.org/datatype3.html

describe 'DataObjects::Sqlite3 with BigDecimal' do
  it_should_behave_like 'supporting BigDecimal'
end
