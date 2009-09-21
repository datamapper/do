require 'lib/do_sqlite3/version'

Gem::Specification.new do |s|
  # basic information
  s.name        = "do_sqlite3"
  s.version     = DataObjects::Sqlite3::VERSION

  # description and details
  s.summary     = 'DataObjects Sqlite3 Driver'
  s.description = "Implements the DataObjects API for Sqlite3"

  # dependencies
  s.add_dependency "addressable", "~>2.1"
  s.add_dependency "extlib", "~>0.9.14"
  s.add_dependency "data_objects", DataObjects::Sqlite3::VERSION

  if JRUBY
    s.add_dependency "jdbc-sqlite3", ">=3.5.8"
    s.add_dependency "do_jdbc", DataObjects::Sqlite3::VERSION
    s.platform = "java"
    # components, files and paths
    s.files = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake",
                        "LICENSE", "Rakefile", "*.{markdown,rdoc,txt,yml}", "lib/*.jar"]
  else
    s.platform    = Gem::Platform::RUBY
    s.extensions << 'ext/do_sqlite3_ext/extconf.rb'
    # components, files and paths
    s.files = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake", "ext/**/*.{rb,c,h}",
                        "LICENSE", "Rakefile", "*.{markdown,rdoc,txt,yml}"]
  end

  # development dependencies
  s.add_development_dependency "rspec", "~>1.2"


  s.require_path = 'lib'

  # documentation
  s.has_rdoc = false

  # project information
  s.homepage          = 'http://github.com/datamapper/do'
  s.rubyforge_project = 'dorb'

  # author and contributors
  s.author      = 'Dirkjan Bussink'
  s.email       = 'd.bussink@gmail.com'
end
