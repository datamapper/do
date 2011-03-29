# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'data_objects/spec/shared/typecast/nil_spec'

describe 'DataObjects::Postgres with Nil' do
  it_should_behave_like 'supporting Nil'
# it_should_behave_like 'supporting writing an Nil'
  it_should_behave_like 'supporting Nil autocasting'
end
