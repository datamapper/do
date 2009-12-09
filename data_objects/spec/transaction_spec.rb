require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Transaction do

  before do
    @connection = mock("connection")
    DataObjects::Connection.should.receive(:new).with("mock://mock/mock").once.and_return(@connection)
    @transaction = DataObjects::Transaction.new("mock://mock/mock")
  end

  it "should have a HOST constant" do
    DataObjects::Transaction::HOST.should.not == nil?
  end

  describe "#initialize" do
    it "should provide a connection" do
      @transaction.connection.should == @connection
    end
    it "should provide an id" do
      @transaction.id.should.not == nil
    end
    it "should provide a unique id" do
      DataObjects::Connection.should.receive(:new).with("mock://mock/mock2").once.and_return(@connection)
      @transaction.id.should.not == DataObjects::Transaction.new("mock://mock/mock2").id
    end
  end

  describe "#close" do
    it "should close its connection" do
      @connection.should.receive(:close).once
      lambda { @transaction.close }.should.not.raise
    end
  end

  [:prepare, :commit_prepared, :rollback_prepared].each do |meth|
    it "should raise NotImplementedError on #{meth}" do
      lambda do @transaction.send(meth) end.should.raise(NotImplementedError)
    end
  end

end
