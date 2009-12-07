begin
  gem('rake-compiler')
  require 'rake/javaextensiontask'

  # Hack to avoid "allocator undefined for Proc" issue when unpacking Gems:
  # gemspec provided by Jeweler uses Rake::FileList for files, test_files and
  # extra_rdoc_files, and procs cannot be marshalled.
  def gemspec
    @clean_gemspec ||= eval("#{Rake.application.jeweler.gemspec.to_ruby}") # $SAFE = 3\n
  end

  Rake::JavaExtensionTask.new('do_h2_ext', gemspec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem_spec|
      gem_spec.post_install_message = <<EOF
==========================================================================

  DataObjects H2 Driver:
    You've installed the binary extension for JRuby (Java platform)

==========================================================================
EOF
    end
  end

  # do_h2 is only available for JRuby: the normal behaviour of rake-compiler
  # is to only chain 'compile:PLATFORM' tasks to 'compile' where PLATFORM is
  # the platform of the current interpreter (i.e. 'compile:java' to 'compile'
  # only if running on JRuby). However, we always want to compile for Java,
  # even if running from MRI.
  task 'compile:do_h2_ext' => ['compile:do_h2_ext:java']
  task 'compile' => ['compile:java']

rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
