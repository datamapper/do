desc 'Builds all gems (native, binaries for JRuby and Windows)'
task :build_all do
  `rake clean`
  `rake build`
  `rake java gem`
  `rake cross native gem RUBY_CC_VERSION=1.8.7:1.9.2`
end

desc 'Release all gems (native, binaries for JRuby and Windows)'
task :release_all => :build_all do
  Dir["pkg/do_mysql-#{DataObjects::Mysql::VERSION}*.gem"].each do |gem_path|
    command = "gem push #{gem_path}"
    puts "Executing #{command.inspect}:"
    sh command
  end
end
