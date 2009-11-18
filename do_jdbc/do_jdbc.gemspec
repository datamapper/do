Gem::Specification.new do |s|
  # basic information
  s.name        = "do_jdbc"
  s.version     = '0.10.1'

  # description and details
  s.summary     = 'DataObjects JDBC support library'
  s.description = "Provides JDBC support for usage in DO drivers for JRuby"

  # dependencies
  s.add_dependency "addressable", "~>2.1"
  s.add_dependency "extlib", "~>0.9.14"
  s.add_dependency "data_objects", '0.10.1'
  s.platform = "java"

  # development dependencies
  s.add_development_dependency "rspec", "~>1.2"

  # components, files and paths
  s.files = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake",
                      "MIT-LICENSE", "Rakefile", "*.{markdown,rdoc,txt,yml}", "lib/*.jar"]

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
