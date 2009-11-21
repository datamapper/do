require 'rubygems'
require 'bacon'
require 'mocha/api'
require 'mocha/object'

dir = File.dirname(__FILE__)
lib_path = File.expand_path("#{dir}/../lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)
require 'data_objects'

# see http://gnufied.org/2008/06/12/making-ruby-bacon-play-with-mocha/
class Bacon::Context
  include Mocha::API
  alias_method :old_it,:it
  def it description,&block
    mocha_setup
    old_it(description,&block)
    mocha_verify
    mocha_teardown
  end
end

require File.expand_path(File.join(File.dirname(__FILE__), 'do_mock'))
require File.expand_path(File.join(File.dirname(__FILE__), 'do_mock2'))

Bacon.summary_on_exit
