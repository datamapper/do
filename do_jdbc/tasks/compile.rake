begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/javaextensiontask'

  def gemspec
    @clean_gemspec ||= Gem::Specification::load(File.expand_path('../../do_jdbc_internal.gemspec', __FILE__))
  end

  Rake::JavaExtensionTask.new('do_jdbc_internal', gemspec) do |ext|
    ext.ext_dir = 'src/main/java'
  end

  # do_jdbc is only available for JRuby: the normal behaviour of rake-compiler
  # is to only chain 'compile:PLATFORM' tasks to 'compile' where PLATFORM is the
  # platform of the current interpreter (i.e. 'compile:java' to 'compile' only
  # if running on JRuby). However, we always want to compile for Java, even if
  # running from MRI.
  task 'compile:do_jdbc_internal' => ['compile:do_jdbc_internal:java']
  task 'compile' => ['compile:java']

rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
