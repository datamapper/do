begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/javaextensiontask'

  def gemspec
    @clean_gemspec ||= Gem::Specification::load(File.expand_path('../../do_hsqldb.gemspec', __FILE__))
  end

  Rake::JavaExtensionTask.new('do_hsqldb', gemspec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.lib_dir   = 'lib/do_hsqldb'
    ext.debug     = ENV.has_key?('DO_JAVA_DEBUG') && ENV['DO_JAVA_DEBUG']
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
  end

  # do_hsqldb is only available for JRuby: the normal behaviour of rake-compiler
  # is to only chain 'compile:PLATFORM' tasks to 'compile' where PLATFORM is the
  # platform of the current interpreter (i.e. 'compile:java' to 'compile' only
  # if running on JRuby). However, we always want to compile for Java, even if
  # running from MRI.
  task 'compile:do_hsqldb' => ['compile:do_hsqldb:java']
  task 'compile' => ['compile:java']

rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
