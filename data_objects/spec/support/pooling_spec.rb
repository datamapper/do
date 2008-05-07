require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'data_objects', 'support', 'pooling')

describe "Object::Pooling" do
  
  before(:all) do
    class Thing
      
      include Object::Pooling
      
      attr_accessor :name
      
      def initialize(name)
        @name = name
      end
      
      def dispose
        @name = nil
      end
      
    end
  end
  
  it "should have a max pool-size" do
    Object::Pooling::size.should == 4
  end
  
  it "should respond to ::new and #release" do
    Thing.should respond_to(:new)
    Thing.instance_methods.should include("release")
  end
  
  it "should raise an error if the target object doesn't implement a `dispose' method" do
    lambda do
      class Durian
        include Object::Pooling
      end.new
    end.should raise_error(Object::Pooling::MustImplementDisposeError)
  end
  
  it "should be able to aquire an object" do    
    bob = Thing.new("bob")
    bob.name.should == 'bob'
    
    fred = Thing.new("fred")
    fred.name.should == 'fred'
    
    Thing::pools['bob'].reserved.should have(1).entries
    Thing::pools['bob'].available.should have(0).entries
    
    Thing::pools['fred'].reserved.should have(1).entries
    Thing::pools['fred'].available.should have(0).entries
    
    bob2 = Thing.new("bob")
    bob2.name.should == 'bob'
    
    Thing::pools['bob'].reserved.should have(2).entries
    Thing::pools['bob'].available.should have(0).entries
    
    bob.release
    Thing::pools['bob'].available.should have(1).entries
    Thing::pools['bob'].reserved.should have(1).entries
    
    bob2.release
    Thing::pools['bob'].available.should have(2).entries
    Thing::pools['bob'].reserved.should have(0).entries
    
    fred.release
  end
  
  it "should allow you to flush all pools, or an individual pool" do
    pending
    
    Thing::pools.flush!
    
    Thing.new('fred')
    Thing.new('bob')
    
    Thing::pools['fred'].reserved.should have(1).entries
    Thing::pools['bob'].reserved.should have(1).entries
    
    Thing::pools['fred'].flush!
    Thing::pools['fred'].reserved.should have(0).entries
    Thing::pools['fred'].available.should have(0).entries
    
    Thing::pools['bob'].flush!
  end
  
  it "should dispose idle available objects"
end