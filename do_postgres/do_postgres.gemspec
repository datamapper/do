Gem::Specification.new do |s|
  # basic information
  s.name        = 'do_postgres'
  s.version     = '0.10.1'

  # description and details
  s.summary     = 'DataObjects PostgreSQL Driver'
  s.description = 'Implements the DataObjects API for PostgreSQL'

  # dependencies
  s.add_dependency 'addressable', '~>2.1'
  s.add_dependency 'data_objects', '0.10.1'

  if RUBY_PLATFORM =~ /java/
    s.add_dependency "jdbc-postgres", ">=8.2"
    s.add_dependency 'do_jdbc', '0.10.1'
    s.platform = 'java'
    # components, files and paths
    s.files = Dir['lib/**/*.rb', 'spec/**/*.rb', 'tasks/**/*.rake',
                  'LICENSE', 'Rakefile', '*.{markdown,rdoc,txt,yml}', 'lib/*.jar']
  else
    s.platform    = Gem::Platform::RUBY
    s.extensions << 'ext/do_postgres_ext/extconf.rb'
    s.files = Dir['lib/**/*.rb', 'spec/**/*.rb', 'tasks/**/*.rake', 'ext/**/*.{rb,c,h}',
                  'LICENSE', 'Rakefile', '*.{markdown,rdoc,txt,yml}']
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
