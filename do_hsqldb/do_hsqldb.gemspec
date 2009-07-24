--- !ruby/object:Gem::Specification 
extensions: []

homepage: http://github.com/datamapper/do
executables: []

version: !ruby/object:Gem::Version 
  version: 0.10.0
post_install_message: 
date: 2009-07-19 22:00:00 +00:00
files: 
- lib/do_hsqldb.rb
- lib/do_hsqldb/version.rb
- spec/command_spec.rb
- spec/connection_spec.rb
- spec/encoding_spec.rb
- spec/reader_spec.rb
- spec/result_spec.rb
- spec/spec_helper.rb
- spec/lib/rspec_immediate_feedback_formatter.rb
- spec/typecast/array_spec.rb
- spec/typecast/bigdecimal_spec.rb
- spec/typecast/boolean_spec.rb
- spec/typecast/byte_array_spec.rb
- spec/typecast/class_spec.rb
- spec/typecast/date_spec.rb
- spec/typecast/datetime_spec.rb
- spec/typecast/float_spec.rb
- spec/typecast/integer_spec.rb
- spec/typecast/nil_spec.rb
- spec/typecast/range_spec.rb
- spec/typecast/string_spec.rb
- spec/typecast/time_spec.rb
- tasks/gem.rake
- tasks/install.rake
- tasks/native.rake
- tasks/release.rake
- tasks/spec.rake
- LICENSE
- Rakefile
- History.txt
- Manifest.txt
- README.txt
- lib/do_hsqldb_ext.jar
rubygems_version: 1.3.4
rdoc_options: []

signing_key: 
cert_chain: []

name: do_hsqldb
has_rdoc: true
platform: java
summary: DataObjects Hsqldb Driver
default_executable: 
bindir: bin
licenses: []

required_rubygems_version: !ruby/object:Gem::Requirement 
  version: 
  requirements: 
  - - '>='
    - !ruby/object:Gem::Version 
      version: "0"
required_ruby_version: !ruby/object:Gem::Requirement 
  version: 
  requirements: 
  - - '>='
    - !ruby/object:Gem::Version 
      version: "0"
require_paths: 
- lib
specification_version: 3
test_files: []

dependencies: 
- !ruby/object:Gem::Dependency 
  type: :runtime
  name: addressable
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    version: 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: "2.0"
- !ruby/object:Gem::Dependency 
  type: :runtime
  name: extlib
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    version: 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: 0.9.12
- !ruby/object:Gem::Dependency 
  type: :runtime
  name: data_objects
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    version: 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.10.0
- !ruby/object:Gem::Dependency 
  type: :runtime
  name: jdbc-hsqldb
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    version: 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: 1.8.0
- !ruby/object:Gem::Dependency 
  type: :runtime
  name: do_jdbc
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    version: 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.10.0
- !ruby/object:Gem::Dependency 
  type: :development
  name: rspec
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    version: 
    requirements: 
    - - ~>
      - !ruby/object:Gem::Version 
        version: 1.2.0
description: Implements the DataObjects API for Hsqldb
email: alex@alexcolesportfolio.com
authors: 
- Alex Coles
extra_rdoc_files: []

requirements: []

rubyforge_project: dorb
autorequire: 
