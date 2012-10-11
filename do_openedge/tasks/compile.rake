begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/javaextensiontask'

  def gemspec
    @clean_gemspec ||= Gem::Specification::load(File.expand_path('../../do_openedge.gemspec', __FILE__))
  end

  Rake::JavaExtensionTask.new('do_openedge', gemspec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.lib_dir   = "lib/#{gemspec.name}"
    ext.debug     = ENV.has_key?('DO_JAVA_DEBUG') && ENV['DO_JAVA_DEBUG']
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem|
      gem.add_dependency 'jdbc-openedge'
      gem.add_dependency 'do_jdbc',       '0.10.10'
    end
  end

  # do_openedge is only available for JRuby: the normal behaviour of rake-compiler
  # is to only chain 'compile:PLATFORM' tasks to 'compile' where PLATFORM is the
  # platform of the current interpreter (i.e. 'compile:java' to 'compile' only
  # if running on JRuby). However, we always want to compile for Java, even if
  # running from MRI.
  task 'compile:do_openedge' => ['compile:do_openedge:java']
  task 'compile' => ['compile:java']

rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
