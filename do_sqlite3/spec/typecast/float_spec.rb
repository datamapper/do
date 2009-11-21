# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/float_spec'

describe 'DataObjects::Sqlite3 with Float' do
  behaves_like 'supporting Float'
end

describe 'DataObjects::Sqlite3 with Float' do
  behaves_like 'supporting Float autocasting'
end
