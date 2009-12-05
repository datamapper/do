tasks_dir = ROOT.parent + 'tasks'

begin
  gem('rake-compiler')
  require 'rake/extensiontask'
  require 'rake/javaextensiontask'

  Rake::ExtensionTask.new('do_mysql_ext', $gemspec) do |ext|

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
    end

  end

  Rake::JavaExtensionTask.new('do_mysql_ext', $gemspec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem|
      gem.add_dependency 'jdbc-mysql', '>=5.0.4'
      gem.add_dependency 'do_jdbc',    '0.10.1'
      gem.post_install_message = <<EOF
==========================================================================

  DataObjects MySQL Driver:
    You've installed the binary extension for JRuby (Java platform)

==========================================================================
EOF
      # components, files and paths
      # gem.files = Dir['lib/**/*.rb', 'spec/**/*.rb', 'tasks/**/*.rake',
      #              'LICENSE', 'Rakefile', '*.{markdown,rdoc,txt,yml}', 'lib/*.jar']
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end

# Stolen from http://github.com/karottenreibe/joker/blob/master/tasks/c_extensions.rake:
# 
# Workaround for rake-compiler, which YAML-dump-loads the gemspec, which leads
# to errors since Procs can't be loaded.
Rake::Task.tasks.each do |task_name|
    case task_name.to_s
    when /^native|java/
        task_name.prerequisites.unshift("fix_rake_compiler_gemspec_dump")
    end
end

task :fix_rake_compiler_gemspec_dump do
    %w{files extra_rdoc_files test_files}.each do |accessor|
        $gemspec.send(accessor).instance_eval { @exclude_procs = Array.new }
    end
end
