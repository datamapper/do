desc 'Builds all gems (native, binaries for JRuby and Windows)'
task :build_all do
  `rake clean`
  `rake java gem`
end

desc 'Release all gems (native, binaries for JRuby and Windows)'
task :release_all => :build_all do
  Dir["pkg/do_hsqldb-#{DataObjects::Hsqldb::VERSION}*.gem"].each do |gem_path|
    command = "gem push #{gem_path}"
    puts "Executing #{command.inspect}:"
    sh command
  end
end
