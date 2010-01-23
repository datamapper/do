# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'

describe DataObjects::SqlServer::Connection do

  before do
    @driver   = CONFIG.scheme
    @user     = CONFIG.user
    @password = CONFIG.pass
    @host     = CONFIG.host
    @port     = CONFIG.port
    @database = CONFIG.database
  end

  behaves_like 'a Connection'
  #behaves_like 'a Connection with authentication support'
  # FIXME: behaves_like 'a Connection with JDBC URL support' if JRUBY
  behaves_like 'a Connection via JDNI' if JRUBY
end
