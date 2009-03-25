# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'data_objects/spec/connection_spec'
require 'cgi'

describe DataObjects::Mysql::Connection do

  before :all do
    @driver = 'mysql'
    @user   = 'root'
    @password = ''
    @host   = 'localhost'
    @port   = 3306
    @database = 'do_test'
    @ssl_query = %W[
      ssl_ca=#{CGI::escape(ssl_config[:ca_cert])}
      ssl_cert=#{CGI::escape(ssl_config[:client_cert])}
      ssl_key=#{CGI::escape(ssl_config[:client_key])}
    ].join('&')
  end

  it_should_behave_like 'a Connection'
  it_should_behave_like 'a Connection with authentication support'
  it_should_behave_like 'a Connection with SSL support'
end
