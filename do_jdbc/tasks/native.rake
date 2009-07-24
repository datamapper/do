if (tasks_dir = ROOT.parent + 'tasks').directory?
  require tasks_dir + 'ext_helper_java'
  setup_java_extension("#{GEM_SPEC.name}_internal", GEM_SPEC, :source_dir => 'src/main/java', :add_buildr_task => false)
end
