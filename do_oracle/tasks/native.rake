begin
  gem('rake-compiler')
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('do_oracle_ext', GEM_SPEC) do |ext|

    oracle_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'oracle'))

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
      ext.config_options << "--with-oracle-include=#{oracle_lib}/include"
      ext.config_options << "--with-oracle-lib=#{oracle_lib}/lib"
    else
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
      ext.cross_config_options << "--with-oracle-include=#{oracle_lib}/include"
      ext.cross_config_options << "--with-oracle-lib=#{oracle_lib}/lib/opt"
    end

  end
rescue LoadError
  warn "To cross-compile, install rake-compiler (gem install rake-compiler)"

  if (tasks_dir = ROOT.parent + 'tasks').directory?
    require tasks_dir + 'ext_helper'
    require tasks_dir + 'ext_helper_java'

    setup_c_extension("#{GEM_SPEC.name}_ext", GEM_SPEC)
    setup_java_extension("#{GEM_SPEC.name}_ext", GEM_SPEC)
  end
end
