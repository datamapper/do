def sudo_gem(cmd)
  sh "#{SUDO} #{RUBY} -S gem #{cmd}", :verbose => false
end

# Installation

desc "Install #{GEM_SPEC.name} #{GEM_SPEC.version}"
task :install => [ :package ] do
  sudo_gem "install pkg/#{GEM_SPEC.name}-#{GEM_SPEC.version} --no-update-sources"
end

desc "Uninstall #{GEM_SPEC.name} #{GEM_SPEC.version}"
task :uninstall => [ :clean ] do
  sudo_gem "uninstall #{GEM_SPEC.name} -v#{GEM_SPEC.version} -I -x"
end
