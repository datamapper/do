require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'spec/rake/spectask'

PLUGIN = "do_jdbc"
NAME = "do_jdbc"
GEM_VERSION = "0.9.0"
AUTHOR = "Alex Coles"
EMAIL = "alex@alexcolesportfolio.com"
HOMEPAGE = "http://dataobjects.dejavu.com"
SUMMARY = "A DataObjects.rb driver for JDBC"

spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO']
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency('data_objects', '>= 0.9.0')
  s.require_path = 'lib'
  s.autorequire = PLUGIN
  s.files = %w(LICENSE README Rakefile TODO) #+ Dir.glob("{lib,specs,ext}/**/*").reject {|x| x =~ /\.(o|bundle)$/ }
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

task :default => [:java_compile, :spec]

def java_classpath_arg # myriad of ways to discover JRuby classpath
  begin
    jruby_cpath = Java::java.lang.System.getProperty('java.class.path')
  rescue => e
  end
  unless jruby_cpath
    jruby_cpath = ENV['JRUBY_PARENT_CLASSPATH'] || ENV['JRUBY_HOME'] &&
      FileList["#{ENV['JRUBY_HOME']}/lib/*.jar"].join(File::PATH_SEPARATOR)
  end
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

task :more_clean do
  rm_rf FileList['derby*']
  rm_rf FileList['test.db.*']
  rm_rf "test/reports"
  rm_f FileList['lib/**/*.jar']
  rm_f "manifest.mf"
end

task :clean => :more_clean

task :filelist do
  puts FileList['pkg/**/*'].inspect
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{NAME}-#{VERSION}}, :verbose => false
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
