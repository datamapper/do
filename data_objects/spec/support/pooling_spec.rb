require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'data_objects', 'support', 'pooling')
require 'timeout'


class SomeResource
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def dispose
    @name = nil
  end
end


describe Object::Pooling do
  it "provides instance method for flushing the pool"

  it "provides access to the pool"
end



describe Object::Pooling::ResourcePool do
  it "responds to aquire"

  it "has a size limit"

  it "has current size"

  it "has a readable set of reserved resources"

  it "has a readable set of available resources"

  it "knows whether it has available resources left"

  it "knows class of resources (objects) it works with"

  it "requires class of resources (objects) it works with to have a dispose instance method"

  it "has a resource environment"

  it "assumes resource environment responds to aquire"

  it "assumes resource environment responds to release"
end
