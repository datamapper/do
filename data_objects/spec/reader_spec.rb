require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Reader do
  subject { command.execute_reader }

  let(:connection)  { DataObjects::Connection.new('mock://localhost')     }
  let(:command)     { connection.create_command('SELECT * FROM example')  }

  after { connection.close }

  context 'should define a standard API' do

    it { should be_a(Enumerable)    }

    it { should respond_to(:close)  }
    it { should respond_to(:next!)  }
    it { should respond_to(:values) }
    it { should respond_to(:fields) }
    it { should respond_to(:each)   }
  end

end
