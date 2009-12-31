require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'

ROOT = Pathname(__FILE__).dirname.expand_path

require ROOT + 'lib/data_objects/version'

JRUBY    = RUBY_PLATFORM =~ /java/
IRONRUBY = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ironruby'
WINDOWS  = Gem.win_platform? || (JRUBY && ENV_JAVA['os.name'] =~ /windows/i)
SUDO     = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])

CLEAN.include(%w[ pkg/ **/*.rbc ])

begin
  gem 'jeweler', '~> 1.4'
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name        = 'data_objects'
    gem.version     = DataObjects::VERSION
    gem.summary     = 'DataObjects basic API and shared driver specifications'
    gem.description = 'Provide a standard and simplified API for communicating with RDBMS from Ruby'
    gem.platform    = Gem::Platform::RUBY
    gem.files       = FileList["lib/**/*.rb", "spec/**/*.rb", "tasks/**/*.rake",
                        "LICENSE", "Rakefile", "*.{markdown,rdoc,txt,yml}"]
    gem.test_files  = FileList['spec/**/*.rb']

    gem.add_dependency 'addressable', '~>2.1'

    gem.add_development_dependency 'bacon', '~>1.1'
    gem.add_development_dependency 'mocha', '~>0.9'
    gem.add_development_dependency 'yard',  '~>0.5'

    gem.rubyforge_project = 'dorb'

    gem.authors     = ['Dirkjan Bussink']
    gem.email       = 'd.bussink@gmail.com'
    gem.homepage    = 'http://github.com/datamapper/do'
  end

  Jeweler::GemcutterTasks.new

  FileList['tasks/**/*.rake'].each { |task| import task }
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end
