begin
  gem('rake-compiler')
  require 'rake/javaextensiontask'

  Rake::JavaExtensionTask.new('do_hsqldb_ext', $gem_spec) do |ext|
    ext.ext_dir   = 'ext-java/src/main/java'
    ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem_spec|
      gem_spec.post_install_message = <<EOF
==========================================================================

  DataObjects HSQLDB Driver:
    You've installed the binary extension for JRuby (Java platform)

==========================================================================
EOF
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
