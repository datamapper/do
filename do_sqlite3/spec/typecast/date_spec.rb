# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/date_spec'

# Sqlite3 doesn't support dates natively, so autocasting is not available:
# http://www.sqlite.org/datatype3.html

describe 'DataObjects::Sqlite3 with Date' do
  behaves_like 'supporting Date'
end
