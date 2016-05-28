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
        cfg.config_file = config[:config_file]
        cfg.cache_timeout = config[:cache_timeout].to_i
        cfg.port = config[:port]
        cfg.auth_file = config[:auth_file]
        cfg.state_file = config[:state_file]
        cfg.environment = config[:environment].to_sym
      end

      # => Launch the API
      ChefRunDeck::API.run!
    end
  end
end
