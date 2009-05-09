begin
  gem('rake-compiler')
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('do_postgres_ext', GEM_SPEC) do |ext|

    postgres_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'pgsql'))

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
      ext.config_options << "--with-pgsql-server-include=#{postgres_lib}/include/server"
      ext.config_options << "--with-pgsql-client-include=#{postgres_lib}/include"
      ext.config_options << "--with-pgsql-win32-include=#{postgres_lib}/include/server/port/win32"
      ext.config_options << "--with-pgsql-client-lib=#{postgres_lib}/lib"
    else
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
      ext.cross_config_options << "--with-pgsql-server-include=#{postgres_lib}/include/server"
      ext.cross_config_options << "--with-pgsql-client-include=#{postgres_lib}/include"
      ext.cross_config_options << "--with-pgsql-win32-include=#{postgres_lib}/include/server/port/win32"
      ext.cross_config_options << "--with-pgsql-client-lib=#{postgres_lib}/lib"
    end

  end
rescue LoadError
  warn "To cross-compile, install rake-compiler (gem install rake-compiler)"
  setup_c_extension('do_postgres_ext', GEM_SPEC)
end
