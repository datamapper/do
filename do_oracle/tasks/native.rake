begin
  gem('rake-compiler')
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('do_oracle_ext', GEM_SPEC) do |ext|

    oracle_lib = File.expand_path(File.join(File.dirname(__FILE__), '..', 'vendor', 'oracle'))

    # automatically add build options to avoid need of manual input
    if RUBY_PLATFORM =~ /mswin|mingw/ then
    else
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
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
