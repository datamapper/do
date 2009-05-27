--- !ruby/object:Gem::Specification 
name: do_jdbc
version: !ruby/object:Gem::Version 
  version: 0.9.13
platform: java
authors: 
- Alex Coles
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
description: Provides JDBC support for usage in DO drivers for JRuby
email: alex@alexcolesportfolio.com
executables: []

extensions: []

extra_rdoc_files: []

files: 
- lib/do_jdbc/date_formatter.rb
- lib/do_jdbc/datetime_formatter.rb
- lib/do_jdbc/time_formatter.rb
- lib/do_jdbc/version.rb
- lib/do_jdbc.rb
- tasks/gem.rake
- tasks/install.rake
- tasks/native.rake
- tasks/release.rake
- MIT-LICENSE
- GPL-LICENSE
- Rakefile
- History.txt
- Manifest.txt
- README.txt
- lib/do_jdbc_internal.jar
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
summary: DataObjects JDBC support library
test_files: []

