# Encoding: UTF-8
# rubocop: disable LineLength, MethodLength, AbcSize
#
# Gem Name:: chef-rundeck
# ChefRunDeck:: CLI
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'mixlib/cli'
require 'chef-rundeck/config'
require 'chef-rundeck/util'

module ChefRunDeck
  #
  # => Chef-RunDeck Launcher
  #
  module CLI
    extend self
    #
    # => Options Parser
    #
    class Options
      # => Mix-In the CLI Option Parser
      include Mixlib::CLI

      option :cache_timeout,
             short: '-t CACHE_TIMEOUT',
             long: '--timeout CACHE_TIMEOUT',
             description: 'Sets the cache timeout in seconds for API query response data.'

      option :config_file,
             short: '-c CONFIG',
             long: '--config CONFIG',
             description: 'The configuration file to use, as opposed to command-line parameters (optional)'

      option :auth_file,
             short: '-a CONFIG',
             long: '--auth-json CONFIG',
             description: "The JSON file containing authorization information (Default: #{Config.auth_file})"

      option :state_file,
             short: '-s STATE',
             long: '--state-json STATE',
             description: "The JSON file containing node state & auditing information (Default: #{Config.state_file})"

      option :chef_api_endpoint,
             short: '-ce ENDPOINT',
             long: '--chef-api-endpoint ENDPOINT',
             description: 'The Chef API Endpoint URL (e.g. https://api.chef.io/)'

      option :chef_api_client,
             short: '-ccn CLIENT_NAME',
             long: '--chef-api-client-name CLIENT_NAME',
             description: 'The name of the Non-Privileged API Client'

      option :chef_api_client_key,
             short: '-cck CLIENT_KEY',
             long: '--chef-api-client-key CLIENT_KEY',
             description: 'The path to the Non-Privileged API Client Keyfile'

      option :chef_api_admin,
             short: '-can ADMIN_NAME',
             long: '--chef-api-admin-name ADMIN_NAME',
             description: 'The name of the Administratively-Privileged API Client'

      option :chef_api_admin_key,
             short: '-cak ADMIN_KEY',
             long: '--chef-api-admin-key ADMIN_KEY',
             description: 'The path to the Administratively-Privileged API Client Keyfile'

      option :rd_node_username,
             short: '-u USERNAME',
             long: '--rundeck-node-user USERNAME',
             description: 'The name of the User Account to place into the RunDeck Resource Provider'

      option :bind,
             short: '-b HOST',
             long: '--bind HOST',
             description: "Listen on Interface or IP (Default: #{Config.bind})"

      option :port,
             short: '-p PORT',
             long: '--port PORT',
             description: "The port to run on. (Default: #{Config.port})"

      option :environment,
             short: '-e ENV',
             long: '--env ENV',
             description: 'Sets the environment for chef-rundeck to execute under. Use "development" for more logging.',
             default: 'production'
    end

    # => Launch the Application
    def run(argv = ARGV)
      # => Parse CLI Configuration
      cli = Options.new
      cli.parse_options(argv)

      # => Parse JSON Config File (If Specified & Exists)
      json_config = Util.parse_json_config(cli.config[:config_file])

      # => Grab the Default Values
      default = ChefRunDeck::Config.options

      # => Merge Configuration (JSON File Wins)
      config = [default, json_config, cli.config].compact.reduce(:merge)

      # => Apply Configuration
      ChefRunDeck::Config.setup do |cfg|
        cfg.config_file         = config[:config_file]
        cfg.cache_timeout       = config[:cache_timeout].to_i
        cfg.bind                = config[:bind]
        cfg.port                = config[:port]
        cfg.auth_file           = config[:auth_file]
        cfg.state_file          = config[:state_file]
        cfg.environment         = config[:environment].to_sym
        cfg.chef_api_endpoint   = config[:chef_api_endpoint]
        cfg.chef_api_client     = config[:chef_api_client]
        cfg.chef_api_client_key = config[:chef_api_client_key]
        cfg.chef_api_admin      = config[:chef_api_admin]
        cfg.chef_api_admin_key  = config[:chef_api_admin_key]
        cfg.rd_node_username    = config[:rd_node_username]
      end

      # => Launch the API
      ChefRunDeck::API.run!
    end
  end
end
