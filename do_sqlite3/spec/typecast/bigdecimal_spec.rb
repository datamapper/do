# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/bigdecimal_spec'

describe 'DataObjects::Sqlite3 with BigDecimal' do
  it_should_behave_like 'supporting BigDecimal'
end
# keep these describe blocks split into two to avoid deadlocks on the
# connection pool
describe 'DataObjects::Sqlite3 with BigDecimal' do
#  it_should_behave_like 'supporting BigDecimal autocasting'
end
