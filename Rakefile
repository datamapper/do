#!/usr/bin/env ruby

# do rake file

require 'pathname'
require 'rubygems'
require 'rake'
require Pathname('spec/rake/spectask')
require Pathname('rake/rdoctask')

DIR = Pathname(__FILE__).dirname.expand_path.to_s

projects = %w[data_objects do_jdbc do_mysql do_postgres do_sqlite3]

namespace :ci do

  projects.each do |gem_name|
    task gem_name do
      ENV['gem_name'] = gem_name

      Rake::Task["ci:run_all"].invoke
    end
  end

  task :run_all => [:spec, :install, :doc, :publish]

  task :spec => :define_tasks do
    Rake::Task["#{ENV['gem_name']}:spec"].invoke
  end

  task :doc => :define_tasks do
    Rake::Task["#{ENV['gem_name']}:doc"].invoke
  end

  task :install do
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
    
    unless FileList["#{DIR}/#{gem_name}/ext/**/extconf.rb"].empty?
      file "#{gem_name}/Makefile" => FileList["#{DIR}/#{gem_name}/ext/**/extconf.rb", "#{DIR}/#{gem_name}/ext/**/*.c", "#{DIR}/#{gem_name}/ext/**/*.h"] do
        system("cd #{gem_name} && ruby ext/extconf.rb")
        system("cd #{gem_name} && make all") || system("cd #{gem_name} && nmake all")
      end
      task "#{gem_name}:spec" => "#{gem_name}/Makefile"
    end

    Spec::Rake::SpecTask.new("#{gem_name}:spec") do |t|
      t.spec_opts = ["--format", "specdoc", "--format", "html:rspec_report.html", "--diff"]
      t.spec_files = Pathname.glob(ENV['FILES'] || DIR + "/#{gem_name}/spec/**/*_spec.rb")
      unless ENV['NO_RCOV']
        t.rcov = true
        t.rcov_opts << '--exclude' << "spec,gems,#{(projects - [gem_name]).join(',')}"
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
