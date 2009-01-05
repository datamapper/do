#
# a version of setup_extension for Java
#
def setup_extension_java(extension_name, gem_spec = nil)
  ext_name = "#{extension_name}.jar"
  directory 'lib'

  desc 'Compile Extension for current Ruby (= compile:jruby)'
  task :compile => [ 'compile:jruby' ] if JRUBY

  namespace :compile do
    desc "Compile Java Extension for JRuby"
    #task :jruby => ["lib/#{ext_name}"]

    task :jruby do
      begin
        # gem 'buildr', '1.3.1.1'
        # require 'buildr'
        # FIXME: this is throwing rspec activation errors
        sh %{jruby -S buildr package}

        buildr_output = extension_name.gsub(/_(ext)$/, '-\1-java-1.0.jar')
        cp "ext-java/target/#{buildr_output}", "lib/#{ext_name}"
      rescue LoadError
        puts "#{spec.name} requires the buildr gem to compile the Java extension"
      end
    end
  end
  file "lib/#{ext_name}" => 'compile:jruby'

end
