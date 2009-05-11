begin
  gem('rake-compiler')
  require 'rake/extensiontask'

  # compile the extension
  if JRUBY
    # XXX: is it necessary to run this everytime?
    Rake::Task['compile:jruby'].invoke
  end

  Rake::ExtensionTask.new('do_sqlite3_ext', GEM_SPEC) do |ext|

    sqlite3_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'sqlite3'))

    ext.cross_compile = true
    ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
    ext.cross_config_options << "--with-sqlite3-dir=#{sqlite3_lib}"

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
      ext.config_options << "--with-sqlite3-dir=#{sqlite3_lib}"
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
