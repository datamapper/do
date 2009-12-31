#
# Standard Bacon configuration for DataObjects spec suite
#
require 'bacon'
require 'data_objects/spec/helpers/immediate_red_green_output'
require 'data_objects/spec/helpers/pending'

Bacon.extend Bacon::ImmediateRedGreenOutput
Bacon.summary_on_exit
