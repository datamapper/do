require File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'data_objects', 'support', 'pooling')
require 'timeout'


class SomeResource
  include Object::Pooling
  attr_reader :name

  def initialize(name = "")
    @name = name
  end

  def dispose
    @name = nil
  end
end

class UndisposableResource
end



describe Object::Pooling::ResourcePool do
  before :each do
    @pool = Object::Pooling::ResourcePool.new(7, SomeResource)
  end

  it "responds to flush!" do
    @pool.should respond_to(:flush!)
  end

  it "responds to aquire" do
    @pool.should respond_to(:aquire)
  end

  it "has a size limit" do
    @pool.size_limit.should == 7
  end

  it "has initial size of zero" do
    @pool.size.should == 0
  end

  it "has a readable set of reserved resources" do
    @pool.reserved.should be_empty
  end

  it "has a readable set of available resources" do
    @pool.available.should be_empty
  end

  it "knows whether it has available resources left" do
    @pool.should respond_to(:available?)
  end

  it "knows class of resources (objects) it works with" do
    @pool.class_of_resources.should == SomeResource
  end

  it "raises exception when given anything but class for resources class" do
    lambda { @pool = Object::Pooling::ResourcePool.new(7, "Hooray!") }.should raise_error(ArgumentError, /class/)
  end

  it "requires class of resources (objects) it works with to have a dispose instance method" do
    lambda { @pool = Object::Pooling::ResourcePool.new(3, UndisposableResource) }.should raise_error(ArgumentError, /dispose/)
  end
end




describe "Aquire from contant size pool" do
  before :each do
    SomeResource.initialize_pool(2)
  end

  it "places initialized instances to the pool" do
    @time = SomeResource.pool.aquire
    SomeResource.pool.size.should == 1
  end

  it "places initialized instance in the reserved set" do
    @time = SomeResource.pool.aquire
    SomeResource.pool.reserved.size.should == 1
  end

  it "raises an exception when pool size limit is hit" do
    @t1 = SomeResource.pool.aquire
    @t2 = SomeResource.pool.aquire

    lambda { SomeResource.pool.aquire }.should raise_error(RuntimeError)
  end

  it "returns last released resource" do
    @t1 = SomeResource.pool.aquire
    @t2 = SomeResource.pool.aquire
    SomeResource.pool.release(@t1)

    SomeResource.pool.aquire.should == @t1
  end

  it "really truly returns last released resource" do
    @t1 = SomeResource.pool.aquire
    SomeResource.pool.release(@t1)

    @t2 = SomeResource.pool.aquire
    SomeResource.pool.release(@t2)

    @t3 = SomeResource.pool.aquire
    SomeResource.pool.release(@t3)

    SomeResource.pool.aquire.should == 1
    @t1.should == @t3
  end
end



describe "Releasing from contant size pool" do
  before :each do
    SomeResource.initialize_pool(2)
  end

  it "decreases size of the pool" do
    @t1 = SomeResource.pool.aquire
    @t2 = SomeResource.pool.aquire
    SomeResource.pool.release(@t1)

    SomeResource.pool.size.should == 1
  end

  it "raises an exception on attempt to releases object not in pool" do
    @t1 = SomeResource.pool.aquire
    @t2 = SomeResource.new

    SomeResource.pool.release(@t1)
    lambda { SomeResource.pool.release(@t2) }.should raise_error(RuntimeError)
  end

  it "disposes released object" do
    @t1 = SomeResource.pool.aquire

    @t1.should_receive(:dispose)
    SomeResource.pool.release(@t1)
  end

  it "removes released object from reserved set" do
    @t1 = SomeResource.pool.aquire

    lambda { SomeResource.pool.release(@t1) }.should change(SomeResource.pool.reserved, :size).by(-1)
  end

  it "returns released object back to available set" do
    @t1 = SomeResource.pool.aquire

    lambda { SomeResource.pool.release(@t1) }.should change(SomeResource.pool.available, :size).by(1)
  end
end



describe "Flushing of contant size pool" do
  before :each do
    SomeResource.initialize_pool(2)

    @t1 = SomeResource.pool.aquire
    @t2 = SomeResource.pool.aquire

    # sanity check
    SomeResource.pool.reserved.should_not be_empty
  end

  it "disposes all pooled objects" do
    [@t1, @t2].each { |instance| instance.should_receive(:dispose) }

    SomeResource.pool.flush!
  end

  it "empties reserved set" do
    SomeResource.pool.flush!

    SomeResource.pool.reserved.should be_empty
  end

  it "returns all instances to available set" do
    SomeResource.pool.flush!

    SomeResource.pool.available.size.should == 2
  end
end
