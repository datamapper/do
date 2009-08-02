require 'rubygems/package_task'

GEM_SPEC = eval(File.read('data_objects.gemspec'))

gem_package = Gem::PackageTask.new(GEM_SPEC) do |pkg|
  pkg.need_tar = false
  pkg.need_zip = false
end
