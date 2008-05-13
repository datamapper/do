require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'data_objects', 'support', 'pooling')
require 'timeout'

describe "Pooled object class" do

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

  it "has a default max pool size" do
    Thing::pools.size.should == 4
  end

  it "blocks aquiring when pool size limit is hit" do
    pending "aquiring possibly should wait for objects to become available"

    # default size is 4
    Thing.new('Grumpy')
    Thing.new('Grumpy')
    Thing.new('Grumpy')
    Thing.new('Grumpy')

    thread = Thread.new { Thing.new('Grumpy') }

    lambda do
      Timeout::timeout(1) { thread.join }
    end.should raise_error(Timeout::Error)

    Thing::pools.flush!
  end

  it "responds to ::new" do
    Thing.should respond_to(:new)
  end

  it "has #release instance method" do
    Thing.instance_methods.should include("release")
  end

  it "should raise an error if the target object doesn't implement a `dispose' method" do
      class Durian
        include Object::Pooling
      end
      lambda do
        Durian.new
      end.should raise_error(Object::Pooling::MustImplementDisposeError)
  end

  it "is able to aquire an object when pool size limit is not hit yet" do
    # first aquired object in pool "bob"
    bob = Thing.new("bob")
    bob.name.should == 'bob'

    fred = Thing.new("fred")
    fred.name.should == 'fred'

    Thing::pools['bob'].reserved.should have(1).entries
    Thing::pools['bob'].available.should have(0).entries

    Thing::pools['fred'].reserved.should have(1).entries
    Thing::pools['fred'].available.should have(0).entries

    # second aquired object in pool "bob"
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

  it "should allow you to flush an individual pool" do
    Thing.new('fred')

    Thing::pools['fred'].reserved.should have(1).entries

    Thing::pools['fred'].flush!

    Thing::pools['fred'].reserved.should have(0).entries
    Thing::pools['fred'].available.should have(0).entries
  end

  it "should allow you to flush all pools at once" do
    Thing.new('fred')
    Thing.new('bob')

    Thing::pools['fred'].reserved.should have(1).entries
    Thing::pools['bob'].reserved.should have(1).entries

    Thing::pools.flush!
    Thing::pools['fred'].reserved.should have(0).entries
    Thing::pools['bob'].reserved.should have(0).entries
  end


  it "should dispose idle available objects"
end




describe Object::Pooling::Pools::Pool, "initially" do
  before :all do
    class Beer
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def dispose
        @name = nil
      end
    end

    @carlsberg = Beer.new("carlsberg")
  end

  before :each do
    @pool = Object::Pooling::Pools::Pool.new(10, Beer, "amstel")
  end

  it "aquires instances of given type" do
    Thread.new do
      @amstel = @pool.send(:aquire_instance!)

      @amstel.should be_an_instance_of(Beer)
      @amstel.name.should == "amstel"
    end
  end

  it "aquires objects in a thread" do
    # we are not in a separate thread
    lambda { @amstel = @pool.send(:aquire_instance!) }.should raise_error(StandardError)
  end

  it "allows reading of size" do
    @pool.size.should == 10
  end

  it "has empty set of reserved objects" do
    @pool.reserved.should be_empty
  end

  it "has empty set of available objects" do
    @pool.available.should be_empty
  end
end



describe Object::Pooling::Pools::Pool, "initially" do
  before :all do
    class Beer
      include Object::Pooling

      attr_reader :name

      def initialize(name)
        @name = name
      end

      def dispose
        @name = nil
      end
    end

    @carlsberg = Beer.new("carlsberg")
  end

  before :each do
    @pool = Object::Pooling::Pools::Pool.new(10, Beer, "amstel")
  end

  it "puts aquired object into available objects set" do
    Thread.new do
      @amstel = @pool.send(:aquire_instance!)

      @pool.available.should_not be_empty
    end
  end
end

