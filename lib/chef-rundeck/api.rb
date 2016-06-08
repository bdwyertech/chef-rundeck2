# Encoding: UTF-8
# rubocop: disable LineLength
#
# Gem Name:: chef-rundeck
# Module:: API
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'sinatra/base'
require 'sinatra/namespace'
require 'json'
require 'rack/cache'
require 'chef-rundeck/auth'
require 'chef-rundeck/chef'
require 'chef-rundeck/config'
require 'chef-rundeck/state'

# => Chef Options Provider for RunDeck
module ChefRunDeck
  # => HTTP API
  class API < Sinatra::Base
    # => Include Modules
    # => include ChefAPI::Resource
    # => include ChefRunDeck::State

    # => def initialize
    # =>   # => Call any Initalize Methods in Included Modules (Superclass)
    # =>   super
    # => end

    #######################
    # =>    Sinatra    <= #
    #######################

    # => Configure Sinatra
    enable :logging, :static, :raise_errors # => disable :dump_errors, :show_exceptions
    set :port, Config.port || 8080
    set :bind, Config.bind || 'localhost'
    set :environment, Config.environment || :production

    # => Enable NameSpace Support
    register Sinatra::Namespace

    if development?
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    use Rack::Cache do
      set :verbose, true
      set :metastore,   'file:' + File.join(Dir.tmpdir, 'rack', 'meta')
      set :entitystore, 'file:' + File.join(Dir.tmpdir, 'rack', 'body')
    end

    ########################
    # =>    JSON API    <= #
    ########################

    # => Current Configuration & Healthcheck Endpoint
    get '/config' do
      content_type 'application/json'
      JSON.pretty_generate(
        [
          ChefRunDeck.inspect + ' is up and running!',
          'Author: ' + Config.author,
          'Environment: ' + Config.environment.to_s,
          'Root: ' + Config.root.to_s,
          'Config File: ' + (Config.config_file if File.exist?(Config.config_file)).to_s,
          'Auth File: ' + (Config.auth_file if File.exist?(Config.auth_file)).to_s,
          'State File: ' + (Config.state_file if File.exist?(Config.state_file)).to_s,
          { State: State.state.map { |n| n[:name] } },
          'Params: ' + params.inspect,
          'Cache Timeout: ' + Config.cache_timeout.to_s,
          'BRIAN IS COOooooooL',
          { 'Sinatra Info' => env }
        ].compact
      )
    end

    get '/state' do
      content_type 'application/json'
      State.state.to_json
    end

    ########################
    # =>    JSON API    <= #
    ########################

    # => Instantiate these blocks on a Per-Project Basis

    namespace '/chef/v1' do
      # => Define our common namespace parameters
      before do
        # => This is a JSON API
        content_type 'application/json'
        # => Grab the Authentication Key if Exists
        params['auth_key'] ||= env['HTTP_AUTHORIZATION']
        # => Make the Params Globally Accessible
        Config.define_setting :query_params, params
        # => Instantiate the Default Client
        Chef.api_client
        # => User Authorization
        Auth.parse(params['auth_user'])
      end

      # => Clean Up
      after do
        # => Reset the API Client to Default Values
        Chef.reset!
        # => Reset Authorization
        Auth.reset!
      end

      get '/state' do
        # => Internal Redirect to Root /state
        call env.merge('PATH_INFO' => '/state')
      end

      # => Retrieve a List of Nodes
      get '/list' do
        cache_control :public, max_age: 30
        Chef.list.to_json
      end

      # => Deliver Nodes the User is Authorized to Delete
      get '/list/:user' do |user|
        State.state.select { |n| n[:creator].casecmp(user) == 0 }.map { |n| n[:name] }.to_json
      end

      # => Check if a Node Exists (Pass regex param for case insensitivity)
      get '/node/:node' do |node|
        cache_control :public, max_age: 30
        regex = true if params['regex'] == '1'
        Chef.get_node(node, regex).to_json
      end

      # => View User Authorization
      get '/auth' do
        # => Return User Authorization
        {
          User: params['auth_user'],
          Admin: Auth.admin?,
          Authorization: Auth.auth,
          Auth_Key_Match?: Auth.key?
        }.to_json
      end

      # => View User Authorization
      post '/auth' do
        # => Return User Authorization
        {
          User: params['auth_user'],
          Admin: Auth.admin?,
          Authorization: Auth.auth,
          Auth_Key_Match?: Auth.key?
        }.to_json
        # => {
        # =>   'Sinatra Info' => env,
        # =>   Headers: headers
        # => }.to_json
      end

      # => Search for Matching Nodes
      get '/search' do
        cache_control :public, max_age: 30
        # => return Chef.search(params['pattern']).to_json if params['pattern']
        Chef.search(params).to_json
      end

      # => Search for Matching Nodes
      get '/test' do
        cache_control :public, max_age: 10
        # => abc =
        # => Chef.reset!
        Chef.search.unshift(Config.options).to_json
        # => Chef.project_settings('project2').to_json
        # => Config.options.to_json
      end

      # => Search for Matching Nodes (Project-Specific)
      get '/:project/search' do |project|
        cache_control :public, max_age: 10
        # => Pass the Project into the Query Parameters
        Config.query_params['project'] = project
        # => Search & Return
        Chef.search.unshift(Config.options).to_json
      end

      # => Add Node to the State
      post '/add/:node/:user' do |node, user|
        State.add_state(node, user, params)
      end

      # => Delete Node from the Chef Server
      post '/delete/:node' do |node|
        unless State.state.any? { |n| n[:name] == node }
          status 404
          return "#{node} not found".to_json
        end
        # => Delete the Node
        Chef.delete(node)
      end
    end
  end
end
