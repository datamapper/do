require 'pathname'
require 'rubygems'
require 'bundler'
require 'rubygems/package_task'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/clean'

ROOT = Pathname(__FILE__).dirname.expand_path

require ROOT + 'lib/data_objects/version'

JRUBY    = RUBY_PLATFORM =~ /java/
IRONRUBY = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ironruby'
WINDOWS  = Gem.win_platform? || (JRUBY && ENV_JAVA['os.name'] =~ /windows/i)
SUDO     = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])

CLEAN.include(%w[ pkg/ **/*.rbc ])

FileList['tasks/**/*.rake'].each { |task| import task }
