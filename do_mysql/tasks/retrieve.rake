begin
  gem 'rake-compiler', '~>0.7'
  require 'rake/clean'
  require 'rake/extensioncompiler'

  # download mysql library and headers
  directory "vendor"

  # only on Windows or cross platform compilation
  def dlltool(dllname, deffile, libfile)
    # define if we are using GCC or not
    if Rake::ExtensionCompiler.mingw_gcc_executable then
      dir = File.dirname(Rake::ExtensionCompiler.mingw_gcc_executable)
      tool = case RUBY_PLATFORM
        when /mingw/
          File.join(dir, 'dlltool.exe')
        when /linux|darwin/
          File.join(dir, "#{Rake::ExtensionCompiler.mingw_host}-dlltool")
      end
      return "#{tool} --dllname #{dllname} --def #{deffile} --output-lib #{libfile}"
    else
      if RUBY_PLATFORM =~ /mswin/ then
        tool = 'lib.exe'
      else
        fail "Unsupported platform for cross-compilation (please, contribute some patches)."
      end
      return "#{tool} /DEF:#{deffile} /OUT:#{libfile}"
    end
  end

  file "vendor/mysql-noinstall-#{BINARY_VERSION}-win32.zip" => ['vendor'] do |t|
    base_version = BINARY_VERSION.gsub(/\.[0-9]+$/, '')
    url = "http://mysql.proserve.nl/Downloads/MySQL-#{base_version}/#{File.basename(t.name)}"
    when_writing "downloading #{t.name}" do
      cd File.dirname(t.name) do
        sh "wget -c #{url} || curl -L -C - -O #{url}"
      end
    end
  end

  file "vendor/mysql-#{BINARY_VERSION}-win32/include/mysql.h" => ["vendor/mysql-noinstall-#{BINARY_VERSION}-win32.zip"] do |t|
    full_file = File.expand_path(t.prerequisites.last)
    when_writing "creating #{t.name}" do
      cd "vendor" do
        sh "unzip #{full_file} mysql-#{BINARY_VERSION}-win32/bin/** mysql-#{BINARY_VERSION}-win32/include/** mysql-#{BINARY_VERSION}-win32/lib/**"
      end
      # update file timestamp to avoid Rake perform this extraction again.
      touch t.name
    end
  end

  # clobber vendored packages
  CLOBBER.include('vendor')

  # vendor:mysql
  task 'vendor:mysql' => ["vendor/mysql-#{BINARY_VERSION}-win32/include/mysql.h"]

  # hook into cross compilation vendored mysql dependency
  if RUBY_PLATFORM =~ /mingw|mswin/ then
    Rake::Task['compile'].prerequisites.unshift 'vendor:mysql'
  else
    if Rake::Task.tasks.map {|t| t.name }.include? 'cross'
      Rake::Task['cross'].prerequisites.unshift 'vendor:mysql'
    end
  end
rescue LoadError
end
