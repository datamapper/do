if (tasks_dir = ROOT.parent + 'tasks').directory?
  require tasks_dir + 'ext_helper_java'
  setup_java_extension("#{GEM_SPEC.name}_ext", GEM_SPEC)
end
