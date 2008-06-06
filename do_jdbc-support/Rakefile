require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

# House-keeping
CLEAN.include 'derby*', 'test.db.*','test/reports', 'test.sqlite3','lib/**/*.jar','manifest.mf'

JRUBY = (RUBY_PLATFORM =~ /java/) rescue nil

spec = Gem::Specification.new do |s|
  s.name              = 'do_jdbc'
  s.version           = '0.9.0.1'
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = true
  s.extra_rdoc_files  = %w[ README MIT-LICENSE GPL-LICENSE TODO ]
  s.summary           = 'A DataObjects.rb driver for JDBC'
  s.description       = s.summary
  s.author            = 'Alex Coles'
  s.email             = 'alex@alexcolesportfolio.com'
  s.homepage          = 'http://rubyforge.org/projects/dorb'
  s.require_path      = 'lib'
  #s.extensions
  s.files             = FileList[ '{lib,spec}/**/*.{class,rb}', 'Rakefile', *s.extra_rdoc_files ]
  s.add_dependency('data_objects', "= #{s.version}")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

task :default => [ :java_compile, :spec ]

def java_classpath_arg # myriad of ways to discover JRuby classpath
  #begin
  #  jruby_cpath = Java::java.lang.System.getProperty('java.class.path')
  #rescue => e
  #end
  #unless jruby_cpath
    jruby_cpath = ENV['JRUBY_PARENT_CLASSPATH'] || ENV['JRUBY_HOME'] &&
      FileList["#{ENV['JRUBY_HOME']}/lib/*.jar"].join(File::PATH_SEPARATOR)
  #end
  jruby_cpath ? "-cp #{jruby_cpath}" : ""
end

desc "Compile the native Java code."
task :java_compile do
  pkg_classes = File.join(*%w(pkg classes))
  jar_name = File.join(*%w(lib do_jdbc_internal.jar))
  mkdir_p pkg_classes
  sh "javac -target 1.5 -source 1.5 -d pkg/classes #{java_classpath_arg} #{FileList['src/java/**/*.java'].join(' ')}"
  sh "jar cf #{jar_name} -C #{pkg_classes} ."
end
file "lib/do_jdbc_internal.jar" => :java_compile

task :filelist do
  puts FileList['pkg/**/*'].inspect
end

task :install => [ :package ] do
  sh %{jruby -S gem install pkg/#{spec.name}-#{spec.version} --no-update-sources}, :verbose => false
end

desc "Run specifications"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ["--format", "specdoc", "--colour"]
  t.spec_files = Dir["spec/**/*_spec.rb"].sort
  #unless ENV['NO_RCOV']
  #  t.rcov = true
  #  t.rcov_opts = ['--exclude', 'spec,environment.rb']
  #end
end
