# Tasks to help in cross-compiling a gem for win32 on a mac or linux system.
#
# Based extensively on:
#   http://tenderlovemaking.com/2008/11/21/cross-compiling-ruby-gems-for-win32/
#
# Will eventually be replaced by:
#   http://github.com/luislavena/rake-compiler
#
# Each gem should define its own library specific code for providing the nessessary
# datastore libraries

def download_file(directory, file)
  when_writing "downloading #{file}" do
    cd(directory) do
      system("wget -c #{file} || curl -C - -O #{file}")
    end
  end
end

# CCROOT = cross-compilation root
STASH = "#{CCROOT}/stash"
CROSS = "#{CCROOT}/cross"

RUBY_VERSION = '1.8.6-p287'

namespace :build do
  # contains downloaded files for cross compilation
  directory STASH
  # contains the cross-compiled ruby and other such gems
  directory CROSS

  desc "Build external dependencies for cross-compilation"
  task :externals => "win32:ruby"

  namespace :win32 do
    # tasks for cross-compiling a ruby distribution

    desc "Build cross-compiled ruby"
    task :ruby => "#{CROSS}/bin/ruby.exe"

    # download ruby
    file "#{STASH}/ruby-#{RUBY_VERSION}.tar.gz" => STASH do
      download_file(STASH, "ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-#{RUBY_VERSION}.tar.gz")
    end

    # extract ruby
    file "#{CROSS}/ruby-#{RUBY_VERSION}" => [CROSS, "#{STASH}/ruby-#{RUBY_VERSION}.tar.gz"] do
      when_writing "extracting ruby" do
        cd(CROSS) do
          sh "tar zxvf #{STASH}/ruby-#{RUBY_VERSION}.tar.gz"
        end
      end
    end

    # compile ruby
    file "#{CROSS}/bin/ruby.exe" => "#{CROSS}/ruby-#{RUBY_VERSION}/Makefile" do
      when_writing "cross-compiling ruby" do
        cd "#{CROSS}/ruby-#{RUBY_VERSION}" do
          sh "make"
          sh "make install"
        end
      end
    end

    file "#{CROSS}/ruby-#{RUBY_VERSION}/Makefile" => ["#{CROSS}/ruby-#{RUBY_VERSION}/Makefile.in.bak"] do
      when_writing "Configuring ruby compilation" do
        cd "#{CROSS}/ruby-#{RUBY_VERSION}" do
          buildopts = if File.exists?('/usr/bin/i586-mingw32msvc-gcc')
            '--host=i586-mingw32msvc --target=i386-mingw32 --build=i686-linux'
          else
            '--host=i386-mingw32 --target=i386-mingw32'
          end
          sh(<<-EOS)
            env \
            ac_cv_func_getpgrp_void=no \
            ac_cv_func_setpgrp_void=yes \
            rb_cv_negative_time_t=no \
            ac_cv_func_memcmp_working=yes \
            rb_cv_binary_elf=no \
            ./configure \
            #{buildopts} \
            --prefix=#{CROSS}
          EOS
        end
      end
    end

    file "#{CROSS}/ruby-#{RUBY_VERSION}/Makefile.in.bak" => "#{CROSS}/ruby-#{RUBY_VERSION}" do
      when_writing "correcting Makefile.in" do
        cd "#{CROSS}/ruby-#{RUBY_VERSION}" do
          cp "Makefile.in", "Makefile.in.bak"
          str = ''
          File.open("Makefile.in", 'rb') do |f|
            f.each_line do |line|
              if line =~ /^\s*ALT_SEPARATOR =/
                warn "replacing alt sep!"
                str << "\t\t " + 'ALT_SEPARATOR = "\\\\"; \\'
                str << "\n"
              else
                str << line
              end
            end
          end
          File.open("Makefile.in", 'wb') { |f| f.write str }
          touch "Makefile.in.bak"
        end
      end
    end

    # corrects for a dodgy ALT_SEPARATOR value in the generated makefile
    # compilation fails without this.
    task :correct_makefile_in do
      when_writing "correcting Makefile.in" do
        makefile_in = "#{CROSS}/ruby-#{RUBY_VERSION}/Makefile.in"
      end
    end
  end
end
