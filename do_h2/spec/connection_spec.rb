# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'

describe DataObjects::H2::Connection do

  before do
    @driver   = 'h2'
    @user     = ''
    @password = ''
    @host     = ''
    @port     = ''
    @database = "#{File.expand_path(File.dirname(__FILE__))}/test.db"
  end

  behaves_like 'a Connection'
  #behaves_like 'a Connection with authentication support'
  behaves_like 'a Connection with JDBC URL support'
  behaves_like 'a Connection via JDNI'
end
