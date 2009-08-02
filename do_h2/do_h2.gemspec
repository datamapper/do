require 'lib/do_h2/version'

Gem::Specification.new do |s|
  # basic information
  s.name        = "do_h2"
  s.version     = DataObjects::H2::VERSION

  # description and details
  s.summary     = 'DataObjects H2 Driver'
  s.description = "Implements the DataObjects API for H2"

  # dependencies
  s.add_dependency "addressable", "~>2.0"
  s.add_dependency "extlib", "~>0.9.12"
  s.add_dependency "data_objects", DataObjects::H2::VERSION
  s.add_dependency "jdbc-h2", "~>1.1.107"
  s.add_dependency "do_jdbc", DataObjects::H2::VERSION

  s.platform = "java"

  # components, files and paths
  s.files = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake",
                      "LICENSE", "Rakefile", "*.{rdoc,txt,yml}", "lib/*.jar"]

  # development dependencies
  s.add_development_dependency 'rspec', '~>1.2.0'

  s.require_path = 'lib'

  # documentation
  s.has_rdoc = false

  # project information
  s.homepage          = 'http://github.com/datamapper/do'
  s.rubyforge_project = 'dorb'

  # author and contributors
  s.author      = 'Alex Coles'
  s.email       = 'alex@alexcolesportfolio.com'
end
