require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::H2" do

  it "should expose the proper DataObjects classes" do
    lambda {
      DataObjects::H2::const_get('Command')
      DataObjects::H2::const_get('Connection')
      DataObjects::H2::const_get('Result')
      DataObjects::H2::const_get('Reader')
      #DataObjects::H2::const_get('Transaction')
    }.should_not raise_error(NameError)

    lambda {
      DataObjects::H2::const_get('NotDoH2Class')
    }.should raise_error(NameError)

    DataObjects::H2::const_get('H2Error').should_not be_nil

    DataObjects::H2::const_get('Command').should_not be_nil
    DataObjects::H2::const_get('Connection').should_not be_nil
    DataObjects::H2::const_get('Result').should_not be_nil
    DataObjects::H2::const_get('Reader').should_not be_nil
    #DataObjects::H2::const_get('Transaction').should_not be_nil
  end

end
