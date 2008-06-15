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
      DataObjects::Jdbc::const_get('NotDoJdbcClass')
    }.should raise_error(NameError)

    DataObjects::Jdbc::const_get('JdbcError').should_not be_nil

    DataObjects::Jdbc::const_get('Command').should_not be_nil
    DataObjects::Jdbc::const_get('Connection').should_not be_nil
    DataObjects::Jdbc::const_get('Result').should_not be_nil
    DataObjects::Jdbc::const_get('Reader').should_not be_nil
    DataObjects::Jdbc::const_get('Transaction').should_not be_nil
  end

end
