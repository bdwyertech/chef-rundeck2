# Encoding: UTF-8
#
# Gem Name:: chef-rundeck
# ChefRunDeck:: Config
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'chef-rundeck/helpers/configuration'
require 'pathname'

module ChefRunDeck
  # => This is the Configuration module.
  module Config
    extend self
    extend Configuration

    # => Gem Root Directory
    define_setting :root, Pathname.new(File.expand_path('../../../', __FILE__))

    # => My Name
    define_setting :author, 'Brian Dwyer - Intelligent Digital Services'

    # => Application Environment
    define_setting :environment, :production

    # => Sinatra Configuration
    define_setting :port, '9125'
    define_setting :bind, 'localhost'
    define_setting :cache_timeout, 30

    # => Config File
    define_setting :config_file, File.join(root, 'config', 'config.json')

    # => Authentication File
    define_setting :auth_file, File.join(root, 'config', 'auth.json')

    # => State File
    define_setting :state_file, File.join(root, 'config', 'state.json')

    #
    # => Facilitate Construction of Values
    #
    # => @return [class_variable]
    #
    def build_config(config = hash)
      config.each do |key, value|
        define_setting key.to_sym, value
      end
    end

    #
    # => List the Configurable Keys as a Hash
    #
    # @return [Hash]
    #
    def options
      map = ChefRunDeck::Config.class_variables.map do |key|
        [key.to_s.tr('@', '').to_sym, class_variable_get(:"#{key}")]
      end
      Hash[map]
    end
  end
end