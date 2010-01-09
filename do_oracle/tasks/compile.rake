begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/extensiontask'
  require 'rake/javaextensiontask'

  # Hack to avoid "allocator undefined for Proc" issue when unpacking Gems:
  # gemspec provided by Jeweler uses Rake::FileList for files, test_files and
  # extra_rdoc_files, and procs cannot be marshalled.
  def gemspec
    @clean_gemspec ||= eval("#{Rake.application.jeweler.gemspec.to_ruby}") # $SAFE = 3\n
  end

  Rake::ExtensionTask.new('do_oracle', gemspec) do |ext|

    ext.lib_dir = "lib/#{gemspec.name}"

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
    else
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
    end

  end

  Rake::JavaExtensionTask.new('do_oracle', gemspec) do |ext|
    ext.lib_dir   = "lib/#{gemspec.name}"
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.debug     = ENV.has_key?('DO_JAVA_DEBUG') && ENV['DO_JAVA_DEBUG']
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem|

      # Hack: Unfortunately there is no way to remove a dependency in the
      #       Gem::Specification API.
      gem.dependencies.delete_if { |d| d.name == 'ruby-oci8'}

      gem.add_dependency "do_jdbc", '0.10.2'
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
