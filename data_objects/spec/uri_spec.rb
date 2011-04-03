require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

describe DataObjects::URI do
  subject { described_class.parse(uri) }

  let(:uri) { 'mock://username:password@localhost:12345/path?encoding=utf8#fragment'  }

  it 'should parse the scheme part' do
    subject.scheme.should == "mock"
  end

  it 'should parse the user part' do
    subject.user.should == "username"
  end

  it 'should parse the password part' do
    subject.password.should == "password"
  end

  it 'should parse the host part' do
    subject.host.should == "localhost"
  end

  it 'should parse the port part' do
    subject.port.should == 12345
  end

  it 'should parse the path part' do
    subject.path.should == "/path"
  end

  it 'should parse the query part' do
    subject.query.should == { "encoding" => "utf8" }
  end

  it 'should parse the fragment part' do
    subject.fragment.should == "fragment"
  end

  it 'should provide a correct string representation' do
    subject.to_s.should == 'mock://username:password@localhost:12345/path?encoding=utf8#fragment'
  end

end
