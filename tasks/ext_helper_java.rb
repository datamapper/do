#
# setup_java_extension create relevant tasks for building Java extensions
#
def setup_java_extension(extension_name, gem_spec = nil, opts = {}, &block)
  ext_name = "#{extension_name}.jar"
  directory 'lib'
  opts = {
    :source_dir => 'ext-java/src/main/java',
    :add_buildr_task => true
    }.merge!(opts)

  desc 'Compile Extension for current Ruby (= compile:jruby)'
  task :compile => [ 'compile:jruby' ] if JRUBY

  namespace :compile do

    desc "Compile Java Extension for JRuby"
    task :jruby => [ :clean ] do
      pkg_classes = File.join(*%w(pkg classes))
      mkdir_p pkg_classes

      not_jruby_compile_msg = <<-EOF
WARNING: You're compiling a binary extension for JRuby, but are using another
interpreter. If your Java classpath or extension dir settings are not correctly
detected, then either check the appropriate environment variables or execute the
Rake compilation task using the JRuby interpreter (`jruby -S rake compile`).
      EOF
      warn(not_jruby_compile_msg) unless defined?(JRUBY_VERSION)

      if extension_name == 'do_jdbc_internal'
        classpath_arg = java_classpath_arg
      else
        unless File.exists?('../do_jdbc/lib/do_jdbc_internal.jar')
          # Check for the presence of do_jdbc_internal.jar in the do_jdbc project
          # which we need to compile against.
          print "\n"; 80.times { print '-' }; print "\n"
          puts "To compile the Java extension, #{extension_name}, you will first need to compile"
          puts "common JDBC support for DataObjects, do_jdbc:"
          puts "cd ../do_jdbc; jruby -S rake compile"
          80.times { print '-' }; print "\n\n"

          raise "Required file for compilation (do_jdbc_internal.jar) not found."
        end

        classpath_arg = java_classpath_arg '../do_jdbc/lib/do_jdbc_internal.jar'
      end

      # Check if DO_JAVA_DEBUG env var was set to TRUE
      # TRUE means compile java classes with debug info
      debug_arg = if ENV['DO_JAVA_DEBUG'] && ENV['DO_JAVA_DEBUG'].upcase.eql?("TRUE")
        '-g'
      else
        ''
      end

      sh "javac #{java_extdirs_arg} -target 1.5 -source 1.5 -Xlint:unchecked #{debug_arg} -d pkg/classes #{classpath_arg} #{FileList["#{opts[:source_dir]}/**/*.java"].join(' ')}"
      sh "jar cf lib/#{ext_name} -C #{pkg_classes} ."
    end

    if opts[:add_buildr_task]
      desc "Compile Java Extension for JRuby (with buildr)"
      task :jruby_buildr do
        begin
          # gem 'buildr', '~>1.3'
          # FIXME: this is throwing RSpec activation errors, as buildr relies on
          # an older version of Rake.

          sh %{#{RUBY} -S buildr package}

          buildr_output = extension_name.gsub(/_(ext)$/, '-\1-java-1.0.jar')
          cp "ext-java/target/#{buildr_output}", "lib/#{ext_name}"
        rescue LoadError
          puts "#{spec.name} requires the buildr gem to compile the Java extension"
        end
      end
    end

  end
  file "lib/#{ext_name}" => 'compile:jruby'

  namespace :build do

    desc 'Build the JRuby gem'
    task :jruby => ['compile:jruby'] do
      spec = gem_spec.dup

      spec.platform = 'java'

      # clear the extension (to avoid RubyGems firing the build process)
      spec.extensions.clear

      # add additional dependencies
      spec.add_dependency('do_jdbc', spec.version)

      # add the pre-compiled binaries to the list of files
      spec.files += ["lib/#{ext_name}"] #Rake::Task['compile:jruby'].prerequisites

      if block_given?
        block.call(spec)
      end

      gem_package = Rake::GemPackageTask.new(spec) do |pkg|
        pkg.need_zip = false
        pkg.need_tar = false
      end
    end

  end

end

#
# Discover Java Extension Directories and build an extdirs argument
#
def java_extdirs_arg
  extdirs = Java::java.lang.System.getProperty('java.ext.dirs') rescue nil
  extdirs = ENV['JAVA_EXT_DIR'] unless extdirs
  java_extdir = extdirs.nil? ? "" : "-extdirs \"#{extdirs}\""
end

#
# Discover the Java/JRuby classpath and build a classpath argument
#
# @params
#   *args:: Additional classpath arguments to append
#
# Copied verbatim from the ActiveRecord-JDBC project. There are a small myriad
# of ways to discover the Java classpath correctly.
#
def java_classpath_arg(*args)
  begin
    cpath  = Java::java.lang.System.getProperty('java.class.path').split(File::PATH_SEPARATOR)
    cpath += Java::java.lang.System.getProperty('sun.boot.class.path').split(File::PATH_SEPARATOR)
    jruby_cpath = cpath.compact.join(File::PATH_SEPARATOR)
  rescue => e
  end
  unless jruby_cpath
    jruby_cpath = ENV['JRUBY_PARENT_CLASSPATH'] || ENV['JRUBY_HOME'] &&
      FileList["#{ENV['JRUBY_HOME']}/lib/*.jar"].join(File::PATH_SEPARATOR)
  end
  raise "JRUBY_HOME or JRUBY_PARENT_CLASSPATH are not set" unless jruby_cpath
  jruby_cpath += File::PATH_SEPARATOR + args.join(File::PATH_SEPARATOR) unless args.empty?
  jruby_cpath ? "-cp \"#{jruby_cpath}\"" : ""
end
