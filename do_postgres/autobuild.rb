#!/usr/bin/env ruby

# If you have Leopard, you can run ./autobuild.rb, and any time you save a file in etc or spec
# it will try to build it, and if it builds, run the specs

require 'open3'
require 'osx/foundation'
OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
include OSX

def make

  stdin, stdout, stderr = Open3.popen3("make")
  return true if stderr.eof?

  puts "MAKE FAILED!"
  while(out = stdout.gets)
    puts out
  end

  while(out = stderr.gets)
    puts out
  end

end

def make_install

  stdin, stdout, stderr = Open3.popen3("make install")
  return true if stderr.eof?

  puts "MAKE INSTALL FAILED!"
  while(out = stdout.gets)
    puts out
  end

  while(out = stderr.gets)
    puts out
  end

end

def run_specs

  puts "="*80
  system("spec -c -fs spec/")
  puts "="*80

end

def build_extension

  if make && make_install
    run_specs
  end

end

# http://rails.aizatto.com/2007/12/11/automatically-restart-scriptserver-for-easier-plugin-development-with-fsevents/

callback = proc do |stream, ctx, numEvents, paths, marks, eventIDs|
  paths.regard_as('*')
  rpaths = []
  length = Dir.pwd.length + 1

  numEvents.times { |i| rpaths << paths[i][length..-1] }

  next if rpaths.select { |path| path =~ /ext|spec/ }.empty?
  build_extension
end

stream = FSEventStreamCreate(KCFAllocatorDefault, callback, nil, [Dir.pwd], KFSEventStreamEventIdSinceNow, 1.0, 0)
unless stream
  puts "Failed to create stream"
  exit
end

FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), KCFRunLoopDefaultMode)
unless FSEventStreamStart(stream)
  puts "Failed to start stream"
  exit
end

begin
  CFRunLoopRun()
rescue Interrupt
  FSEventStreamStop(stream)
  FSEventStreamInvalidate(stream)
  FSEventStreamRelease(stream)
end
