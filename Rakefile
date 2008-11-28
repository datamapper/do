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

WINDOWS = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/) rescue nil
SUDO    = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])

# projects = %w[data_objects do_jdbc do_mysql do_postgres do_sqlite3]
# Took out do_jdbc since it doesn't build yet.
projects = %w[data_objects do_mysql do_postgres do_sqlite3]
projects += %w[do_jdbc do_derby do_hsqldb] if RUBY_PLATFORM =~ /java/

desc 'Release all do gems'
task :release do
  projects.each do |dir|
    Dir.chdir(dir){ sh "rake release VERSION=#{ENV["VERSION"]}" }
  end
end

desc 'Run CI tasks'
task :ci do
  projects.each do |gem_name|
    Dir.chdir(gem_name){ sh("rake ci") }
  end
end

desc 'Run the specification'
task :spec do
  projects.each do |gem_name|
    Dir.chdir(gem_name){ sh("rake spec") }
  end
end

desc 'Install the do gems'
task :install do
  projects.each do |gem_name|
    cd(File.join(File.dirname(__FILE__), gem_name))
    sh('rake install; true')
  end
end
