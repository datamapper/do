begin
  gem('rake-compiler')
  require 'rake/javaextensiontask'

  Rake::JavaExtensionTask.new('do_jdbc_internal', $spec) do |ext|
    ext.ext_dir = 'src/main/java'
    #ext.classpath = '../do_jdbc/lib/do_jdbc_internal.jar'
    ext.java_compiling do |gem_spec|
      gem_spec.post_install_message = <<EOF
==========================================================================

  DataObjects JDBC Support Library:
    You've installed the JDBC Support Library for JRuby (Java platform)

==========================================================================
EOF
    end
  end
rescue LoadError
  warn "To compile, install rake-compiler (gem install rake-compiler)"
end
