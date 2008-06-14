require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Derby" do

  it "should expose the proper DataObjects classes" do
    lambda {
      DataObjects::Derby::const_get('Command')
      DataObjects::Derby::const_get('Connection')
      DataObjects::Derby::const_get('Result')
      DataObjects::Derby::const_get('Reader')
      #DataObjects::Derby::const_get('Transaction')
    }.should_not raise_error(NameError)

    lambda {
      DataObjects::Derby::const_get('NotDoDerbyClass')
    }.should raise_error(NameError)

    DataObjects::Derby::const_get('DerbyError').should_not be_nil

    DataObjects::Derby::const_get('Command').should_not be_nil
    DataObjects::Derby::const_get('Connection').should_not be_nil
    DataObjects::Derby::const_get('Result').should_not be_nil
    DataObjects::Derby::const_get('Reader').should_not be_nil
    #DataObjects::Derby::const_get('Transaction').should_not be_nil
  end

end
