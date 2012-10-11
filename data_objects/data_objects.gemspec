# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{data_objects}
  s.version = "0.10.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dirkjan Bussink"]
  s.description = %q{Provide a standard and simplified API for communicating with RDBMS from Ruby}
  s.email = %q{d.bussink@gmail.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "ChangeLog.markdown",
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "lib/data_objects.rb",
    "lib/data_objects/byte_array.rb",
    "lib/data_objects/command.rb",
    "lib/data_objects/connection.rb",
    "lib/data_objects/error.rb",
    "lib/data_objects/error/connection_error.rb",
    "lib/data_objects/error/data_error.rb",
    "lib/data_objects/error/integrity_error.rb",
    "lib/data_objects/error/sql_error.rb",
    "lib/data_objects/error/syntax_error.rb",
    "lib/data_objects/error/transaction_error.rb",
    "lib/data_objects/extension.rb",
    "lib/data_objects/logger.rb",
    "lib/data_objects/pooling.rb",
    "lib/data_objects/quoting.rb",
    "lib/data_objects/reader.rb",
    "lib/data_objects/result.rb",
    "lib/data_objects/spec/lib/pending_helpers.rb",
    "lib/data_objects/spec/lib/ssl.rb",
    "lib/data_objects/spec/setup.rb",
    "lib/data_objects/spec/shared/command_spec.rb",
    "lib/data_objects/spec/shared/connection_spec.rb",
    "lib/data_objects/spec/shared/encoding_spec.rb",
    "lib/data_objects/spec/shared/error/sql_error_spec.rb",
    "lib/data_objects/spec/shared/quoting_spec.rb",
    "lib/data_objects/spec/shared/reader_spec.rb",
    "lib/data_objects/spec/shared/result_spec.rb",
    "lib/data_objects/spec/shared/typecast/array_spec.rb",
    "lib/data_objects/spec/shared/typecast/bigdecimal_spec.rb",
    "lib/data_objects/spec/shared/typecast/boolean_spec.rb",
    "lib/data_objects/spec/shared/typecast/byte_array_spec.rb",
    "lib/data_objects/spec/shared/typecast/class_spec.rb",
    "lib/data_objects/spec/shared/typecast/date_spec.rb",
    "lib/data_objects/spec/shared/typecast/datetime_spec.rb",
    "lib/data_objects/spec/shared/typecast/float_spec.rb",
    "lib/data_objects/spec/shared/typecast/integer_spec.rb",
    "lib/data_objects/spec/shared/typecast/ipaddr_spec.rb",
    "lib/data_objects/spec/shared/typecast/nil_spec.rb",
    "lib/data_objects/spec/shared/typecast/other_spec.rb",
    "lib/data_objects/spec/shared/typecast/range_spec.rb",
    "lib/data_objects/spec/shared/typecast/string_spec.rb",
    "lib/data_objects/spec/shared/typecast/time_spec.rb",
    "lib/data_objects/transaction.rb",
    "lib/data_objects/uri.rb",
    "lib/data_objects/utilities.rb",
    "lib/data_objects/version.rb",
    "spec/command_spec.rb",
    "spec/connection_spec.rb",
    "spec/do_mock.rb",
    "spec/do_mock2.rb",
    "spec/pooling_spec.rb",
    "spec/reader_spec.rb",
    "spec/result_spec.rb",
    "spec/spec_helper.rb",
    "spec/transaction_spec.rb",
    "spec/uri_spec.rb",
    "tasks/release.rake",
    "tasks/spec.rake",
    "tasks/yard.rake",
    "tasks/yardstick.rake"
  ]
  s.homepage = %q{http://github.com/datamapper/do}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dorb}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataObjects basic API and shared driver specifications}
  s.test_files = [
    "spec/command_spec.rb",
    "spec/connection_spec.rb",
    "spec/do_mock.rb",
    "spec/do_mock2.rb",
    "spec/pooling_spec.rb",
    "spec/reader_spec.rb",
    "spec/result_spec.rb",
    "spec/spec_helper.rb",
    "spec/transaction_spec.rb",
    "spec/uri_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, ["~> 2.1"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<yard>, ["~> 0.5"])
    else
      s.add_dependency(%q<addressable>, ["~> 2.1"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<yard>, ["~> 0.5"])
    end
  else
    s.add_dependency(%q<addressable>, ["~> 2.1"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<yard>, ["~> 0.5"])
  end
end
