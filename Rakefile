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
    t.spec_opts = ["--format", "specdoc", "--colour"]
    t.spec_files = Pathname.glob(ENV['FILES'] || DIR + '/**/spec/**/*_spec.rb')    
    unless ENV['NO_RCOV']
      t.rcov = true
      t.rcov_opts << '--exclude' << 'spec'
      t.rcov_opts << '--text-summary'
      t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
      t.rcov_opts << '--only-uncovered'
    end
  end

end
