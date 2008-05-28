require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "DataObjects::Jdbc::Reader" do
  
  it "should have close, should, values, fields methods" do
    reader = DataObjects::Jdbc::const_get('Reader').new
    reader.should respond_to(:close)
    reader.should respond_to(:next!)
    reader.should respond_to(:values)
    reader.should respond_to(:fields)
    reader.should_not respond_to(:not_a_reader_method)
  end
  
end