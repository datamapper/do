require 'lib/do_oracle/version'

Gem::Specification.new do |s|
  # basic information
  s.name        = "do_oracle"
  s.version     = DataObjects::Oracle::VERSION

  # description and details
  s.summary     = 'DataObjects Oracle Driver'
  s.description = "Implements the DataObjects API for Oracle"

  # dependencies
  s.add_dependency "addressable", "~>2.0"
  s.add_dependency "extlib", "~>0.9.12"
  s.add_dependency "data_objects", DataObjects::Oracle::VERSION

  if JRUBY
    # no jdbc-oracle available
    # s.add_dependency "jdbc-mysql", ">=5.0.4"
    s.add_dependency "do_jdbc", DataObjects::Oracle::VERSION
    s.platform = "java"
    s.files = Dir['lib/**/*.rb', 'spec/**/*.rb', 'tasks/**/*.rake',
                  'LICENSE', 'Rakefile', '*.{rdoc,txt,yml}', 'lib/*.jar']
  else
    s.add_dependency "ruby-oci8", "~>2.0"
    s.platform    = Gem::Platform::RUBY
    s.extensions << 'ext/do_oracle_ext/extconf.rb'
    s.files = Dir['lib/**/*.rb', 'spec/**/*.rb', 'tasks/**/*.rake', 'ext/**/*.{rb,c,h}',
                  'LICENSE', 'Rakefile', '*.{rdoc,txt,yml}']
  end


  # development dependencies
  s.add_development_dependency 'rspec', '~>1.2.0'

  s.require_path = 'lib'

  # documentation
  s.has_rdoc = false

  # project information
  s.homepage          = 'http://github.com/datamapper/do'
  s.rubyforge_project = 'dorb'

  # author and contributors
  s.author      = 'Raimonds Simanovskis'
  s.email       = 'raimonds.simanovskis@gmail.com'
end
