Gem::Specification.new do |s|
  # basic information
  s.name        = "do_hsqldb"
  s.version     = '0.10.1'

  # description and details
  s.summary     = 'DataObjects Hsqldb Driver'
  s.description = "Implements the DataObjects API for Hsqldb"

  # dependencies
  s.add_dependency "addressable", "~>2.1"
  s.add_dependency "data_objects", '0.10.1'
  s.add_dependency "jdbc-hsqldb", "~>1.8.0"
  s.add_dependency "do_jdbc", '0.10.1'

  s.platform = "java"

  # components, files and paths
  s.files = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake",
                      "LICENSE", "Rakefile", "*.{markdown,rdoc,txt,yml}", "lib/*.jar"]

  # development dependencies
  s.add_development_dependency 'bacon', '~>1.1'

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
