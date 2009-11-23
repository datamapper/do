if (tasks_dir = ROOT.parent + 'tasks').directory?
  require tasks_dir + 'ext_helper_java'
  setup_java_extension("#{$gemspec.name}_internal", $gemspec, :source_dir => 'src/main/java', :add_buildr_task => false)
end

task :compile => ["compile:jruby"]
