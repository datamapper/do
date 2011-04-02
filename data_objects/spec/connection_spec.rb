require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Connection do
  subject { klass.new(url) }

  let(:klass) { DataObjects::Connection }

  after(:each) { subject.close }

  context 'should define a standard API' do
    let(:url)   { 'mock://localhost'      }

    it { should respond_to(:dispose)        }
    it { should respond_to(:create_command) }

    it 'should have #to_s that returns the connection uri string' do
      subject.to_s.should == 'mock://localhost'
    end

  end

  describe 'initialization' do

    context 'should accept a connection uri as a Addressable::URI' do
      let(:url)  { Addressable::URI::parse('mock://localhost/database') }

      # NOTE: Using its results in an error, as subject gets redefined:
      #       NoMethodError: undefined method `close' for "mock://localhost/database":String
      # its(:to_s) { should == 'mock://localhost/database' }
      it { subject.to_s.should == 'mock://localhost/database' }
     end

    context 'should return the Connection specified by the scheme' do
      let(:url)  { Addressable::URI.parse('mock://localhost/database') }

      it { should be_kind_of(DataObjects::Mock::Connection) }
      it { should be_kind_of(DataObjects::Pooling)          }
    end

    context 'should return the Connection specified by the scheme without pooling' do
      let(:url)  { Addressable::URI.parse('java://jdbc/database?scheme=mock2') }

      it { should_not be_kind_of(DataObjects::Pooling) }
    end
  end

end
