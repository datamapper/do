# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/typecast/nil_spec'

describe 'DataObjects::SqlServer with Nil' do
  behaves_like 'supporting Nil'
  behaves_like 'supporting writing an Nil'
  behaves_like 'supporting Nil autocasting'
end
