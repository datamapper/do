require 'rake/testtask'

spec_defaults = lambda do |spec|
  spec.libs   << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.verbose = true
end

Rake::TestTask.new(:spec => [ :clean, :compile ], &spec_defaults)
Rake::TestTask.new(:spec_no_compile, &spec_defaults)

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |spec|
    spec.libs   << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.verbose = true
  end
rescue LoadError
  task :rcov do
    abort 'RCov is not available. In order to run rcov, you must: gem install rcov'
  end
end
