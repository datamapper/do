require 'pathname'
require 'rubygems'
require 'rake'
require 'rake/rdoctask'

ROOT     = Pathname(__FILE__).dirname.expand_path
JRUBY    = RUBY_PLATFORM =~ /java/
IRONRUBY = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ironruby'
WINDOWS  = Gem.win_platform? || (JRUBY && ENV_JAVA['os.name'] =~ /windows/i)
SUDO     = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])

# RCov is run by default, except on the JRuby and IronRuby platforms, or if NO_RCOV env is true
RUN_RCOV = JRUBY || IRONRUBY ? false : (ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true)

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

tasks = {
  :spec    => 'Run the specification',
  :install => 'Install the do gems',
  :package => 'Package the do gems',
  :clean   => 'clean temporary files',
  :clobber => 'clobber temporary files',
}

tasks.each do |name, description|
  desc description
  task name do
    projects.each do |gem_name|
      Dir.chdir(gem_name){ rake name }
    end
  end
end
