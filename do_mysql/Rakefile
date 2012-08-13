require 'pathname'
require 'rubygems'
require 'bundler'
require 'rubygems/package_task'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/clean'

ROOT = Pathname(__FILE__).dirname.expand_path

require ROOT + 'lib/do_mysql/version'

JRUBY    = RUBY_PLATFORM =~ /java/
IRONRUBY = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ironruby'
WINDOWS  = Gem.win_platform? || (JRUBY && ENV_JAVA['os.name'] =~ /windows/i)
SUDO     = WINDOWS ? '' : ('sudo' unless ENV['SUDOLESS'])
BINARY_VERSION = '5.1.65'

CLEAN.include(%w[ {tmp,pkg}/ **/*.{o,so,bundle,jar,log,a,gem,dSYM,obj,pdb,exp,DS_Store,rbc,db} ext/do_mysql/Makefile ext-java/target ])


if JRUBY
  Rake::Task['build'].clear_actions   if Rake::Task.task_defined?('build')
  Rake::Task['install'].clear_actions if Rake::Task.task_defined?('install')
  task :build => [ :java, :gem ]
  task :install do
    sh "#{Config::CONFIG['RUBY_INSTALL_NAME']} -S gem install pkg/do_mysql-#{DataObjects::Mysql::VERSION}-java.gem"
  end
end

FileList['tasks/**/*.rake'].each { |task| import task }
