#!/usr/bin/env ruby

# do rake file

require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/clean'
require Pathname('spec/rake/spectask')
require Pathname('rake/rdoctask')

ROOT = Pathname(__FILE__).dirname.expand_path

CLEAN.include '**/{pkg,log,coverage}'

WINDOWS = (RUBY_PLATFORM =~ /mswin|mingw|bccwin|cygwin/) rescue nil
JRUBY   = (RUBY_PLATFORM =~ /java/) rescue nil

# sudo is used by default, except on Windows, or if SUDOLESS env is true
SUDO = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])
# RCov is run by default, except on the JRuby platform, or if NO_RCOV env is true
RUN_RCOV = JRUBY ? false : (ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true)

projects = %w[data_objects do_mysql do_postgres do_sqlite3]
projects += %w[do_jdbc do_derby do_hsqldb] if JRUBY

def rake(*args)
  ruby "-S", "rake", *args # #{$0}
end

desc 'Release all do gems'
task :release do
  projects.each do |dir|
    Dir.chdir(dir){ rake "release VERSION=#{ENV["VERSION"]}" }
  end
end

desc 'Run CI tasks'
task :ci do
  projects.each do |gem_name|
    Dir.chdir(gem_name){ rake 'ci' }
  end
end

desc 'Run the specification'
task :spec do
  projects.each do |gem_name|
    Dir.chdir(gem_name){ rake 'spec' }
  end
end

desc 'Install the do gems'
task :install do
  projects.each do |gem_name|
    cd(File.join(File.dirname(__FILE__), gem_name))
    rake 'install'
  end
end
