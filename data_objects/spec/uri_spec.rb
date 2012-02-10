require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::URI do
  subject { described_class.parse(uri) }

  context 'parsing parts' do
    let(:uri) { 'mock://username:password@localhost:12345/path?encoding=utf8#fragment'  }

    its(:scheme)    { should == 'mock'      }
    its(:user)      { should == 'username'  }
    its(:password)  { should == 'password'  }
    its(:host)      { should == 'localhost' }
    its(:port)      { should == 12345       }
    its(:path)      { should == '/path'     }
    its(:query)     { should == { 'encoding' => 'utf8' } }
    its(:fragment)  { should == 'fragment'  }

    it 'should provide a correct string representation' do
      subject.to_s.should == 'mock://username@localhost:12345/path?encoding=utf8#fragment'
    end
  end

  context 'parsing JDBC URL parts' do
    let(:uri) { 'jdbc:mock://username:password@localhost:12345/path?encoding=utf8#fragment'  }

    its(:scheme)    { should == 'jdbc'      }
    its(:subscheme) { should == 'mock'      }
    its(:user)      { should == 'username'  }
    its(:password)  { should == 'password'  }
    its(:host)      { should == 'localhost' }
    its(:port)      { should == 12345       }
    its(:path)      { should == '/path'     }
    its(:query)     { should == { 'encoding' => 'utf8' } }
    its(:fragment)  { should == 'fragment'  }

    it 'should provide a correct string representation' do
      subject.to_s.should == 'jdbc:mock://username@localhost:12345/path?encoding=utf8#fragment'
    end
  end

  context 'parsing parts' do
    let(:uri) { 'java:comp/env/jdbc/TestDataSource'  }

    its(:scheme)    { should == 'java' }
    its(:path)      { should == 'comp/env/jdbc/TestDataSource'     }

    it 'should provide a correct string representation' do
      subject.to_s.should == 'java:comp/env/jdbc/TestDataSource'
    end
  end

end
