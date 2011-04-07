# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{do_postgres}
  s.version = "0.10.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dirkjan Bussink"]
  s.date = %q{2011-03-29}
  s.description = %q{Implements the DataObjects API for PostgreSQL}
  s.email = %q{d.bussink@gmail.com}
  s.extensions = ["ext/do_postgres/extconf.rb"]
  s.extra_rdoc_files = [
    "ChangeLog.markdown",
    "LICENSE",
    "README.markdown"
  ]
  s.files = [
    "ChangeLog.markdown",
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "ext/do_postgres/compat.h",
    "ext/do_postgres/do_common.c",
    "ext/do_postgres/do_common.h",
    "ext/do_postgres/do_postgres.c",
    "ext/do_postgres/error.h",
    "ext/do_postgres/extconf.rb",
    "ext/do_postgres/pg_config.h",
    "lib/do_postgres.rb",
    "lib/do_postgres/encoding.rb",
    "lib/do_postgres/transaction.rb",
    "lib/do_postgres/version.rb",
    "spec/command_spec.rb",
    "spec/connection_spec.rb",
    "spec/encoding_spec.rb",
    "spec/error/sql_error_spec.rb",
    "spec/reader_spec.rb",
    "spec/result_spec.rb",
    "spec/spec_helper.rb",
    "spec/typecast/array_spec.rb",
    "spec/typecast/bigdecimal_spec.rb",
    "spec/typecast/boolean_spec.rb",
    "spec/typecast/byte_array_spec.rb",
    "spec/typecast/class_spec.rb",
    "spec/typecast/date_spec.rb",
    "spec/typecast/datetime_spec.rb",
    "spec/typecast/float_spec.rb",
    "spec/typecast/integer_spec.rb",
    "spec/typecast/nil_spec.rb",
    "spec/typecast/other_spec.rb",
    "spec/typecast/range_spec.rb",
    "spec/typecast/string_spec.rb",
    "spec/typecast/time_spec.rb",
    "tasks/compile.rake",
    "tasks/release.rake",
    "tasks/retrieve.rake",
    "tasks/spec.rake"
  ]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dorb}
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{DataObjects PostgreSQL Driver}
  s.test_files = [
    "spec/command_spec.rb",
    "spec/connection_spec.rb",
    "spec/encoding_spec.rb",
    "spec/error/sql_error_spec.rb",
    "spec/reader_spec.rb",
    "spec/result_spec.rb",
    "spec/spec_helper.rb",
    "spec/typecast/array_spec.rb",
    "spec/typecast/bigdecimal_spec.rb",
    "spec/typecast/boolean_spec.rb",
    "spec/typecast/byte_array_spec.rb",
    "spec/typecast/class_spec.rb",
    "spec/typecast/date_spec.rb",
    "spec/typecast/datetime_spec.rb",
    "spec/typecast/float_spec.rb",
    "spec/typecast/integer_spec.rb",
    "spec/typecast/nil_spec.rb",
    "spec/typecast/other_spec.rb",
    "spec/typecast/range_spec.rb",
    "spec/typecast/string_spec.rb",
    "spec/typecast/time_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<data_objects>, ["= 0.10.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.5"])
      s.add_development_dependency(%q<rake-compiler>, ["~> 0.7"])
    else
      s.add_dependency(%q<data_objects>, ["= 0.10.3"])
      s.add_dependency(%q<rspec>, ["~> 2.5"])
      s.add_dependency(%q<rake-compiler>, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<data_objects>, ["= 0.10.3"])
    s.add_dependency(%q<rspec>, ["~> 2.5"])
    s.add_dependency(%q<rake-compiler>, ["~> 0.7"])
  end
end
