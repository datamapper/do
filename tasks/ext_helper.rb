require 'rbconfig'

#
# setup_c_extension create relevant tasks, wraps them into 'compile'
# also will set a task named 'native' that will change the supplied
# Gem::Specification and inject into the pre-compiled binaries. if no gem_spec
# is supplied, no native task get defined.
#
def setup_c_extension(extension_name, gem_spec = nil)
  # use the DLEXT for the true extension name
  ext_name = "#{extension_name}.#{RbConfig::CONFIG['DLEXT']}"

  # we need lib
  directory 'lib'

  # verify if the extension is in a folder
  ext_dir = File.join('ext', extension_name)
  unless File.directory?(ext_dir)
    # the extension is in the root of ext.
    ext_dir = 'ext'
  end

  # getting this file is part of the compile task
  desc "Compile Extension for current Ruby (= compile:mri)"
  task :compile => [ 'compile:mri' ] unless JRUBY

  namespace :compile do
    desc 'Compile C Extension for Ruby 1.8 (MRI)'
    task :mri => [:clean, "rake:compile:lib/#{ext_name}"]

    task "#{ext_dir}/#{ext_name}" => FileList["#{ext_dir}/Makefile", "#{ext_dir}/*.c", "#{ext_dir}/*.h"] do
      # Visual C make utility is named 'nmake', MinGW conforms GCC 'make' standard.
      make_cmd = RUBY_PLATFORM =~ /mswin/ ? 'nmake' : 'make'
      Dir.chdir(ext_dir) do
        sh make_cmd
      end
    end

    file "#{ext_dir}/Makefile" => "#{ext_dir}/extconf.rb" do
      Dir.chdir(ext_dir) do
        ruby 'extconf.rb'
      end
    end
    task "lib/#{ext_name}" => ['lib', "#{ext_dir}/#{ext_name}"] do
      cp "#{ext_dir}/#{ext_name}", "lib/#{ext_name}"
    end
  end

  unless Rake::Task.task_defined?('native')
    if gem_spec
      desc "Build Extensions into native binaries."
      task :native => [:compile] do |t|
        # use CURRENT platform instead of RUBY
        gem_spec.platform = Gem::Platform::CURRENT

        # clear the extension (to avoid RubyGems firing the build process)
        gem_spec.extensions.clear

        # add the precompiled binaries to the list of files
        # (taken from compile task dependency)
        gem_spec.files += ["lib/#{ext_name}"]
      end
    end
  end
end
