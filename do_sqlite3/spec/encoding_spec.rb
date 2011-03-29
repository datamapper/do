# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/shared/encoding_spec'

describe DataObjects::Sqlite3::Connection do
  it_should_behave_like 'returning correctly encoded strings for the default database encoding'
  it_should_behave_like 'returning correctly encoded strings for the default internal encoding'
end
