Gem::Specification.new do |s|
  # basic information
  s.name        = "do_sqlserver"
  s.version     = '0.10.1'

  # description and details
  s.summary     = 'DataObjects SqlServer Driver'
  s.description = "Implements the DataObjects API for SqlServer"

  # dependencies
  s.add_dependency "addressable", "~>2.1"
  s.add_dependency "data_objects", '0.10.1'

  if JRUBY
    # DataObjects.rb project bundles the jTDS JDBC Driver for SQL Server (LGPL-
    # Licensed) and wraps it as a gem. In the repository it may be found in the
    # ROOT/jdbc_drivers directory.

    s.add_dependency "do_jdbc-sqlserver", "1.2.4"
    s.add_dependency "do_jdbc", '0.10.1'
    s.platform = "java"
  else
    s.add_dependency 'dbi', '0.4.2'
    s.add_dependency 'dbd-odbc', '0.2.5'
    s.platform    = Gem::Platform::RUBY
  end


  # development dependencies
  s.add_development_dependency 'bacon', '~>1.1'

  # components, files and paths
  s.files = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake", "ext/**/*.{rb,c}",
                      "LICENSE", "Rakefile", "*.{markdown,rdoc,txt,yml}", "lib/*.jar"]

  s.require_path = 'lib'

  # documentation
  s.has_rdoc = false

  # project information
  s.homepage          = 'http://github.com/datamapper/do'
  s.rubyforge_project = 'dorb'

  # author and contributors
  s.author      = 'Clifford Heath'
  s.email       = 'clifford.heath@gmail.com'
end
