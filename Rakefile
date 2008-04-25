#!/usr/bin/env ruby

# do rake file

require 'pathname'
require 'rubygems'
require 'rake'
require Pathname('spec/rake/spectask')
require Pathname('rake/rdoctask')

DIR = Pathname(__FILE__).dirname.expand_path.to_s


task :default => 'do:spec'

namespace :do do

  desc "Run specifications"
  Spec::Rake::SpecTask.new('spec') do |t|
    Dir.chdir("data_objects") && system("rake spec")
    Dir.chdir("..")
    Dir.chdir("do_mysql") && system("rake spec")
    Dir.chdir("..")
    Dir.chdir("do_sqlite3") && system("rake spec")
    Dir.chdir("..")
    Dir.chdir("do_postgres") && system("rake spec")
  end

end
