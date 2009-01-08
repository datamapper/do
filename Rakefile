require 'pathname'
require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

ROOT    = Pathname(__FILE__).dirname.expand_path
JRUBY   = RUBY_PLATFORM =~ /java/
WINDOWS = Gem.win_platform?
SUDO    = (WINDOWS || JRUBY) ? '' : ('sudo' unless ENV['SUDOLESS'])

# RCov is run by default, except on the JRuby platform, or if NO_RCOV env is true
RUN_RCOV = JRUBY ? false : (ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true)

projects = %w[data_objects]
projects += %w[do_jdbc do_derby do_h2 do_hsqldb] if JRUBY
projects += %w[do_mysql do_postgres do_sqlite3]

def rake(cmd)
  ruby "-S rake #{cmd}", :verbose => false
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
    Dir.chdir(gem_name){ rake 'install' }
  end
end

desc 'Package the do gems'
task :package do
  projects.each do |gem_name|
    Dir.chdir(gem_name){ rake 'package' }
  end
end

%w[ clean clobber ].each do |command|
  desc "#{command} temporary files"
  task command do
    projects.each do |gem_name|
      Dir.chdir(gem_name){ rake command }
    end
  end
end
