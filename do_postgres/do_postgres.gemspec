--- !ruby/object:Gem::Specification 
name: do_postgres
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
  name: data_objects
  type: :runtime
  version_requirement: 
  version_requirements: !ruby/object:Gem::Requirement 
    requirements: 
    - - "="
      - !ruby/object:Gem::Version 
        version: 0.9.13
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
description: Implements the DataObjects API for PostgreSQL
email: d.bussink@gmail.com
executables: []

extensions: 
- ext/do_postgres_ext/extconf.rb
extra_rdoc_files: []

files: 
- lib/do_postgres/transaction.rb
- lib/do_postgres/version.rb
- lib/do_postgres.rb
- spec/command_spec.rb
- spec/connection_spec.rb
- spec/encoding_spec.rb
- spec/lib/rspec_immediate_feedback_formatter.rb
- spec/reader_spec.rb
- spec/result_spec.rb
- spec/spec_helper.rb
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
- tasks/retrieve.rake
- tasks/spec.rake
- ext/do_postgres_ext/extconf.rb
- ext/do_postgres_ext/do_postgres_ext.c
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
summary: DataObjects PostgreSQL Driver
test_files: []

