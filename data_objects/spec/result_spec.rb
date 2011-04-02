require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::Result do
  subject { command.execute_non_query }

  let(:connection)  { DataObjects::Connection.new('mock://localhost')     }
  let(:command)     { connection.create_command('SELECT * FROM example')  }

  after { connection.close }

  context 'should define a standard API' do

    it 'should provide the number of affected rows' do
      should respond_to(:to_i)
      subject.to_i.should == 0
    end

    it 'should provide the id of the inserted row' do
      should respond_to(:insert_id)
    end

  end
end
