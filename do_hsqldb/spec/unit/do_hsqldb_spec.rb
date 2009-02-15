require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Hsqldb" do

  it "should expose the proper DataObjects classes" do
    lambda {
      DataObjects::Hsqldb::const_get('Command')
      DataObjects::Hsqldb::const_get('Connection')
      DataObjects::Hsqldb::const_get('Result')
      DataObjects::Hsqldb::const_get('Reader')
      # DataObjects::Hsqldb::const_get('Transaction')
    }.should_not raise_error(NameError)

    lambda {
      DataObjects::Hsqldb::const_get('NotDoJdbcClass')
    }.should raise_error(NameError)

    DataObjects::Hsqldb::const_get('HsqldbError').should_not be_nil

    DataObjects::Hsqldb::const_get('Command').should_not be_nil
    DataObjects::Hsqldb::const_get('Connection').should_not be_nil
    DataObjects::Hsqldb::const_get('Result').should_not be_nil
    DataObjects::Hsqldb::const_get('Reader').should_not be_nil
    #DataObjects::Hsqldb::const_get('Transaction').should_not be_nil
  end

end
