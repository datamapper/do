# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/bigdecimal_spec'

describe 'DataObjects::SqlServer with BigDecimal' do
  behaves_like 'supporting BigDecimal'
  behaves_like 'supporting BigDecimal autocasting'
end
