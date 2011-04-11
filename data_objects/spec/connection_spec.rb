require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require 'stringio'

describe DataObjects::Connection do
  subject { connection }

  let(:connection) { described_class.new(uri) }

  after { connection.close }

  context 'should define a standard API' do
    let(:uri)   { 'mock://localhost'      }

    it { should respond_to(:dispose)        }
    it { should respond_to(:create_command) }

    its(:to_s)  { should == 'mock://localhost' }
  end

  describe 'initialization' do

    context 'with a connection uri as a Addressable::URI' do
      let(:uri)  { Addressable::URI::parse('mock://localhost/database') }

      it { should be_kind_of(DataObjects::Mock::Connection) }
      it { should be_kind_of(DataObjects::Pooling)          }

      its(:to_s) { should == 'mock://localhost/database' }
    end

    [
      'java:comp/env/jdbc/DataSource?driver=mock2',
      Addressable::URI.parse('java:comp/env/jdbc/DataSource?driver=mock2')
    ].each do |jndi_url|
    context 'should return the Connection specified by the scheme without pooling' do
      let(:uri)  { jndi_url }

      it { should be_kind_of(DataObjects::Mock2::Connection) }
      it { should_not be_kind_of(DataObjects::Pooling)       }
    end
  end

    %w(
      jdbc:mock:memory::
      jdbc:mock://host/database
      jdbc:mock://host:6969/database
      jdbc:mock:thin:host:database
      jdbc:mock:thin:@host.domain.com:6969:database
      jdbc:mock://server:6969/database;property=value;
      jdbc:mock://[1111:2222:3333:4444:5555:6666:7777:8888]/database
    ).each do |jdbc_url|
      context "with JDBC URL '#{jdbc_url}'" do
        let(:uri)  { jdbc_url }

        it { should be_kind_of(DataObjects::Mock::Connection) }
      end
    end

  end

end
