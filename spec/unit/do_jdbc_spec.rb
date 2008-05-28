require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc" do

  it "should expose the proper DataObjects classes" do

    lambda {
      DataObjects::Jdbc::const_get('Command')
      DataObjects::Jdbc::const_get('Connection')
      DataObjects::Jdbc::const_get('Result')
      DataObjects::Jdbc::const_get('Reader')
      DataObjects::Jdbc::const_get('Transaction')
    }.should_not raise_error(NameError)

    lambda {
      DataObjects::Jdbc::const_get('NotAClass')
    }.should raise_error(NameError)

    DataObjects::Jdbc::const_get('Command').should_not be_nil
    DataObjects::Jdbc::const_get('Connection').should_not be_nil
    DataObjects::Jdbc::const_get('Result').should_not be_nil
    DataObjects::Jdbc::const_get('Reader').should_not be_nil
    DataObjects::Jdbc::const_get('Transaction').should_not be_nil

    #DataObjects::JDBC::const_get('Command').should be_kind_of(DataObjects::Command)
    #DataObjects::JDBC::const_get('Connection').should be_kind_of(DataObjects::Connection)
    #DataObjects::JDBC::const_get('Result').should be_kind_of(DataObjects::Result)
    #DataObjects::JDBC::const_get('Reader').should be_kind_of(DataObjects::Reader)
    #DataObjects::JDBC::const_get('Transaction').should be_kind_of(DataObjects::Transaction)

    #puts(DataObjects::JDBC::const_get('Reader').kind_of?(DataObjects::Reader))
    #puts(DataObjects::JDBC::const_get('Reader').inspect)
  end

  it "should raise error on bad connection string"

end
