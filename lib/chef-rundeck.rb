# encoding: UTF-8
# rubocop: disable LineLength
# Chef Provider for RunDeck
# Brian Dwyer - Intelligent Digital Services - 5/14/16

require 'chef-rundeck/cli'
require 'chef-rundeck/config'
require 'chef-rundeck/state'
require 'chef-rundeck/util'
require 'chef-rundeck/version'

# => Chef RunDeck Options Provider API
module ChefRunDeck
  # => The Sinatra API should be Lazily-Loaded, such that the CLI arguments and/or configuration files are respected
  autoload :API, 'chef-rundeck/api'
end
