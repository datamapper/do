# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/command_spec'

describe DataObjects::Sqlite3::Command do
  behaves_like 'a Command'
end
