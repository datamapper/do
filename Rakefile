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

namespace :ci do
  
  %w[data_objects do_jdbc do_mysql do_postgres do_sqlite3].each do |gem_name|
    task gem_name do
      ENV['gem_name'] = gem_name
      
      Rake::Task["ci:run_all"].invoke
    end
  end
  
  task :run_all => [:prepare, :spec, :install, :doc, :publish]
  
  task :prepare do
    sh %{cd #{ENV['gem_name']} && rake gem}
  end
  
  task :spec => :define_tasks do
    Rake::Task["#{ENV['gem_name']}:spec"].invoke
  end
  
  task :doc => :define_tasks do
    Rake::Task["#{ENV['gem_name']}:doc"].invoke
  end
  
  task :install do
    ENV['sudoless'] = 'true'
    sh %{cd #{ENV['gem_name']} && rake install}
  end
  
  task :publish do
    out = ENV['CC_BUILD_ARTIFACTS'] || "out"
    mkdir_p out unless File.directory? out if out

    mv "rdoc", "#{out}/rdoc" if out
    mv "coverage", "#{out}/coverage_report" if out && File.exists?("coverage")
    mv "rspec_report.html", "#{out}/rspec_report.html" if out
  end
  
  task :define_tasks do
    gem_name = ENV['gem_name']
    
    Spec::Rake::SpecTask.new("#{gem_name}:spec") do |t|
      t.spec_opts = ["--format", "specdoc", "--format", "html:rspec_report.html", "--diff"]
      t.spec_files = Pathname.glob(ENV['FILES'] || DIR + "/#{gem_name}/spec/**/*_spec.rb")
      unless ENV['NO_RCOV']
        t.rcov = true
        t.rcov_opts << '--exclude' << 'spec'
        t.rcov_opts << '--text-summary'
        t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
        t.rcov_opts << '--only-uncovered'
      end
    end
    
    Rake::RDocTask.new("#{gem_name}:doc") do |t|
      t.rdoc_dir = 'rdoc'
      t.title    = gem_name
      t.options  = ['--line-numbers', '--inline-source', '--all']
      t.rdoc_files.include("#{gem_name}/lib/**/*.rb", "#{gem_name}/ext/**/*.c")
    end
  end
end