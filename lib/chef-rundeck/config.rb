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

    # => Project Configuration File
    define_setting :projects_file, File.join(root, 'config', 'projects.json')

    #
    # => Chef API Configuration
    #
    # => Chef Endpoint
    define_setting :chef_api_endpoint, 'https://api.chef.io'

    # => Unprivileged Client
    define_setting :chef_api_client # => Username
    define_setting :chef_api_client_key # => Path to Key

    # => Administratively-Privileged Client
    define_setting :chef_api_admin # => Username
    define_setting :chef_api_admin_key # => Path to Key

    #
    # => RunDeck Node Resource Configuration
    #
    # => Default Username (nil)
    define_setting :rd_node_username, nil

    #
    # => Facilitate Dynamic Addition of Configuration Values
    #
    # => @return [class_variable]
    #
    def add(config = {})
      config.each do |key, value|
        define_setting key.to_sym, value
      end
    end

    #
    # => Facilitate Dynamic Removal of Configuration Values
    #
    # => @return nil
    #
    def clear(config)
      Array(config).each do |setting|
        delete_setting setting
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
