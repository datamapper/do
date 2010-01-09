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

  Rake::ExtensionTask.new('do_mysql', gemspec) do |ext|
    ext.lib_dir = "lib/#{gemspec.name}"
    mysql_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', "mysql-#{BINARY_VERSION}-win32"))

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
      ext.config_options << "--with-mysql-include=#{mysql_lib}/include"
      ext.config_options << "--with-mysql-lib=#{mysql_lib}/lib/opt"
    else
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
      ext.cross_config_options << "--with-mysql-include=#{mysql_lib}/include"
      ext.cross_config_options << "--with-mysql-lib=#{mysql_lib}/lib/opt"

      ext.cross_compiling do |gemspec|
        gemspec.post_install_message = <<-POST_INSTALL_MESSAGE

  ======================================================================================================

    You've installed the binary version of #{gemspec.name}.
    It was built using MySQL version #{BINARY_VERSION}.
    It's recommended to use the exact same version to avoid potential issues.

    At the time of building this gem, the necessary DLL files where available
    in the following download:

    http://dev.mysql.com/get/Downloads/MySQL-5.0/mysql-noinstall-#{BINARY_VERSION}-win32.zip/from/pick

    You can put the lib\\opt\\libmysql.dll available in this package in your Ruby bin
    directory, for example C:\\Ruby\\bin

  ======================================================================================================

        POST_INSTALL_MESSAGE
      end

    end

  end

  Rake::JavaExtensionTask.new('do_mysql', gemspec) do |ext|
    ext.lib_dir   = "lib/#{gemspec.name}"
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.debug     = ENV.has_key?('DO_JAVA_DEBUG') && ENV['DO_JAVA_DEBUG']
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem|
      gem.add_dependency 'jdbc-mysql', '>=5.0.4'
      gem.add_dependency 'do_jdbc',    '0.10.2'
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
