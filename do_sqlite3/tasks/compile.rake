begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/extensiontask'
  require 'rake/javaextensiontask'

  def gemspec
    @clean_gemspec ||= Gem::Specification::load(File.expand_path('../../do_sqlite3.gemspec', __FILE__))
  end

  unless JRUBY
    Rake::ExtensionTask.new('do_sqlite3', gemspec) do |ext|

      sqlite3_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'sqlite3'))

      ext.lib_dir = "lib/#{gemspec.name}"

      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
      ext.cross_config_options << "--with-sqlite3-dir=#{sqlite3_lib}"

      ext.cross_compiling do |gemspec|
        gemspec.post_install_message = <<-POST_INSTALL_MESSAGE

  =============================================================================

    You've installed the binary version of #{gemspec.name}.
    It was built using Sqlite3 version #{BINARY_VERSION}.
    It's recommended to use the exact same version to avoid potential issues.

    At the time of building this gem, the necessary DLL files where available
    in the following download:

    http://www.sqlite.org/sqlitedll-#{BINARY_VERSION}.zip

    You can put the sqlite3.dll available in this package in your Ruby bin
    directory, for example C:\\Ruby\\bin

  =============================================================================

        POST_INSTALL_MESSAGE
      end

      # automatically add build options to avoid need of manual input
      if RUBY_PLATFORM =~ /mswin|mingw/ then
        ext.config_options << "--with-sqlite3-dir=#{sqlite3_lib}"
      end

    end
  end

  Rake::JavaExtensionTask.new('do_sqlite3', gemspec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.lib_dir   = "lib/#{gemspec.name}"
    ext.debug     = ENV.has_key?('DO_JAVA_DEBUG') && ENV['DO_JAVA_DEBUG']
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem|
      gem.add_dependency 'jdbc-sqlite3', '>=3.5.8'
      gem.add_dependency 'do_jdbc',      '0.10.6'
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
