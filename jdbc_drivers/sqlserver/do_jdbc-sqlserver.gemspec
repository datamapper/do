(in /Users/paul/projects/forks/do/jdbc_drivers/sqlserver)
Gem::Specification.new do |s|
  s.name = %q{do_jdbc-sqlserver}
  s.version = "1.2.2"
  s.platform = %q{java}

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [""]
  s.date = %q{2008-08-27}
  s.description = %q{JDBC Driver for Sql Server, packaged as a Gem}
  s.email = [""]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "LGPL-LICENSE", "Manifest.txt", "README.txt", "Rakefile", "lib/do_jdbc/sqlserver.rb", "lib/do_jdbc/sqlserver_version.rb", "lib/jtds-1.2.2.jar"]
  s.homepage = %q{http://rubyforge.org/projects/dorb}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dorb}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{JDBC Driver for Sql Server, packaged as a Gem}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<data_objects>, [">= 0.9.5"])
      s.add_development_dependency(%q<hoe>, [">= 1.7.0"])
    else
      s.add_dependency(%q<data_objects>, [">= 0.9.5"])
      s.add_dependency(%q<hoe>, [">= 1.7.0"])
    end
  else
    s.add_dependency(%q<data_objects>, [">= 0.9.5"])
    s.add_dependency(%q<hoe>, [">= 1.7.0"])
  end
end
