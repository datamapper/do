if (tasks_dir = ROOT.parent + 'tasks').directory?
  require tasks_dir + 'ext_helper_java'
  setup_java_extension("#{$gemspec.name}_ext", $gemspec)
end

task :compile => ["compile:jruby"]
