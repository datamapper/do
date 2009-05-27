--- !ruby/object:Gem::Specification 
name: data_objects
version: !ruby/object:Gem::Version 
  version: 0.9.13
platform: ruby
authors: 
- Dirkjan Bussink
autorequire: 
bindir: bin
cert_chain: []

date: 2009-05-27 00:00:00 -07:00
default_executable: 
dependencies: 
- !ruby/object:Gem::Dependency 
  name: addressable
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: "2.0"
    version: 
- !ruby/object:Gem::Dependency 
  name: extlib
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: 0.9.12
    version: 
- !ruby/object:Gem::Dependency 
  name: rspec
  type: :development
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: 1.2.0
    version: 
description: Provide a standard and simplified API for communicating with RDBMS from Ruby
email: d.bussink@gmail.com
executables: []

extensions: []

extra_rdoc_files: []

files: 
- lib/data_objects/command.rb
- lib/data_objects/connection.rb
- lib/data_objects/logger.rb
- lib/data_objects/quoting.rb
- lib/data_objects/reader.rb
- lib/data_objects/result.rb
- lib/data_objects/spec/command_spec.rb
- lib/data_objects/spec/connection_spec.rb
- lib/data_objects/spec/encoding_spec.rb
- lib/data_objects/spec/quoting_spec.rb
- lib/data_objects/spec/reader_spec.rb
- lib/data_objects/spec/result_spec.rb
- lib/data_objects/spec/typecast/array_spec.rb
- lib/data_objects/spec/typecast/bigdecimal_spec.rb
- lib/data_objects/spec/typecast/boolean_spec.rb
- lib/data_objects/spec/typecast/byte_array_spec.rb
- lib/data_objects/spec/typecast/class_spec.rb
- lib/data_objects/spec/typecast/date_spec.rb
- lib/data_objects/spec/typecast/datetime_spec.rb
- lib/data_objects/spec/typecast/float_spec.rb
- lib/data_objects/spec/typecast/integer_spec.rb
- lib/data_objects/spec/typecast/ipaddr_spec.rb
- lib/data_objects/spec/typecast/nil_spec.rb
- lib/data_objects/spec/typecast/range_spec.rb
- lib/data_objects/spec/typecast/string_spec.rb
- lib/data_objects/spec/typecast/time_spec.rb
- lib/data_objects/transaction.rb
- lib/data_objects/uri.rb
- lib/data_objects/version.rb
- lib/data_objects.rb
- spec/command_spec.rb
- spec/connection_spec.rb
- spec/do_mock.rb
- spec/lib/pending_helpers.rb
- spec/lib/rspec_immediate_feedback_formatter.rb
- spec/reader_spec.rb
- spec/result_spec.rb
- spec/spec_helper.rb
- spec/transaction_spec.rb
- spec/uri_spec.rb
- tasks/gem.rake
- tasks/install.rake
- tasks/release.rake
- tasks/spec.rake
- LICENSE
- Rakefile
- History.txt
- Manifest.txt
- README.txt
has_rdoc: true
homepage: http://github.com/datamapper/do
licenses: []

post_install_message: 
rdoc_options: []

require_paths: 
- lib
required_ruby_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
required_rubygems_version: !ruby/object:Gem::Requirement 
  requirements: 
  - - ">="
    - !ruby/object:Gem::Version 
      version: "0"
  version: 
requirements: []

rubyforge_project: dorb
rubygems_version: 1.3.3
signing_key: 
specification_version: 3
summary: DataObjects basic API and shared driver specifications
test_files: []

