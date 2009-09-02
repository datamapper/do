unless JRUBY  # do nothing, as the MRI-driver uses DBI, not a native extension
  task :compile do; end;
end

if (tasks_dir = ROOT.parent + 'tasks').directory?
  require tasks_dir + 'ext_helper_java'
  setup_java_extension("#{GEM_SPEC.name}_ext", GEM_SPEC)
end
