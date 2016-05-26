# encoding: UTF-8
# rubocop: disable ClassLength, LineLength, MethodLength
# Chef Provider for RunDeck
# Brian Dwyer - Intelligent Digital Services - 5/14/16

require 'sinatra/base'
require 'sinatra/namespace'
require 'chef-api'
require 'json'
require 'pathname'
require 'rack/cache'

# => Chef RunDeck Options Provider API
class ChefRunDeck < Sinatra::Base
  # => Include Modules
  include ChefAPI::Resource

  class << self
    attr_accessor :auth_file
    attr_accessor :config_file
    attr_accessor :state_file
    attr_accessor :cache_timeout
    attr_accessor :oauth_token
    attr_accessor :config

    # => Function to get Directory
    def root
      @root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end

  # => Initialize Required Objects
  def initialize
    # => Don't Overwrite the Sinatra::Base Superclass Initialize Method
    super
    # => Read the State
    @state ||= parse_json_config(ChefRunDeck.state_file) || []

    # => Define Authorization
    @auth = (auth = {}) && (auth['roles'] = [])
  end

  ######################
  # =>  Definitions  <=#
  ######################

  # => Sanitize Configuration
  def reset
    # => Reset the API Client to Default Values
    ChefAPI.reset!
  end

  # => Define JSON Parser
  def parse_json_config(file = nil, symbolize = true)
    return unless file && ::File.exist?(file.to_s)
    begin
      ::JSON.parse(::File.read(file.to_s), symbolize_names: symbolize)
    rescue JSON::ParserError
      return
    end
  end

  # => Define JSON Writer
  def write_json_config(file, object)
    return unless file && object
    begin
      File.open(file, 'w') { |f| f.write(JSON.pretty_generate(object)) }
    end
  end

  #########################
  # =>     ChefAPI     <= #
  #########################

  def api_client
    # => Configure a Chef API Client
    ChefAPI.endpoint = 'https://chef.contoso.com/organizations/contoso'
    ChefAPI.client = 'rundeck-chef-client'
    ChefAPI.key = '~/.chef/CHEF_CONTOSO/rundeck-chef-client.pem'
  end

  def admin_api_client
    # => Configure an Administrative Chef API Client
    ChefAPI.endpoint = 'https://chef.contoso.com/organizations/contoso'
    ChefAPI.client = 'bdwyer'
    ChefAPI.key = '~/.chef/CHEF_CONTOSO/bdwyer.pem'
  end

  def delete(node)
    # => Make sure the Node Exists
    return unless Node.exists?(node)

    unless auth['admin']
      # => Limit the Deletion to a Specific Role for Non-Admin's
      run_list = Node.fetch(node).run_list
      return unless run_list.empty? || auth['roles'].any? { |role| run_list.any? { |r| r =~ /#{role}/i } }
    end

    # => Initialize the Admin API Client Settings
    admin_api_client

    # => Delete the Client & Node Object
    Client.delete(node)
    Node.delete(node)
  end

  #############################
  # =>    Authorization    <= #
  #############################

  # => This holds the Authorization as defined by Initialize Method
  attr_accessor :auth

  def parse_auth
    # => parse_json_config(ChefRunDeck.auth_file)
    authfile = ChefRunDeck.auth_file
    File.mtime(auth_file) if File.exist?(auth_file)
    # => File.open('/path/to/file.extension', 'w') {|f| f.write(Marshal.dump(m)) }
    # => { token: 'abc123' }
  end

  # => g.include?('bdwyer') && g['bdwyer']['roles'].any? { |r| ['admin', 'project'].include? r }
  # => def default_auth
  # =>   {
  # =>     bdwyer: {
  # =>       auth_key: 'abcd',
  # =>       roles: ['admin']
  # =>     },
  # =>     testme: {
  # =>       roles: ['alpha']
  # =>     }
  # =>   }
  # =>   def abc
  # => end

  ##############################
  # =>   State Operations   <= #
  ##############################

  # => Populated by Initialize Method
  attr_accessor :state

  def find_state(hash)
    state.detect { |h| h[:name].casecmp(hash[:name]) == 0 }
  end

  def update_state(hash)
    existing = state.detect { |h| h[:name].casecmp(hash[:name]) == 0 }
    if existing
      state.delete(existing)
      audit_string = [DateTime.now, hash[:creator]].join(' - ')
      existing[:last_modified] = existing[:last_modified].is_a?(Array) ? existing[:last_modified].take(5).unshift(audit_string) : [audit_string]
      hash = existing
    end
    # => Update the State
    state.push(hash).uniq!
    write_state
  end

  def write_state
    # => Write Out the Updated State
    write_json_config(ChefRunDeck.state_file, state)

    # => Return the Updated State
    # => @state = state
  end

  #############################
  # =>    Serialization    <= #
  #############################

  def serialize(response)
    # => Serialize Object into JSON Array
    JSON.pretty_generate(response.map(&:name).sort_by(&:downcase))
  end

  def serialize_revisions(branches, tags)
    # => Serialize Branches/Tags into JSON Array
    # => Branches = String, Tags = Key/Value
    branches = branches.map(&:name).sort_by(&:downcase)
    tags = tags.map(&:name).sort_by(&:downcase).reverse.map { |tag| { name: "Tag: #{tag}", value: tag } }
    JSON.pretty_generate(branches + tags)
  end

  ######################
  # =>    Search    <= #
  ######################

  def partial_search
    search_filter = {
      name: ['name'],
      kernel_machine: ['kernel', 'machine'],
      kernel_os: ['kernel', 'os'],
      fqdn: ['fqdn'],
      run_list: ['run_list'],
      roles: ['roles'],
      recipes: ['recipes'],
      chef_environment: ['chef_environment'],
      platform: ['platform'],
      platform_version: ['platform_version'],
      tags: ['tags'],
      hostname: ['hostname']
    }

    result = PartialSearch.query(:node, search_filter, '*:*', start: 1)
    result.rows.first['hostname']
  end
  # => Sample JSON Node
  # {
  #   "localhost": {
  #     "nodename": "localhost",
  #     "hostname": "localhost",
  #     "osVersion": "4.4.0-22-generic",
  #     "osFamily": "unix",
  #     "osArch": "amd64",
  #     "description": "Rundeck server node",
  #     "osName": "Linux",
  #     "username": "rundeck"
  #   }
  # }

  #######################
  # =>    Sinatra    <= #
  #######################

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

  # => Current Configuration & Healthcheck Endpoint
  get '/' do
    content_type 'text/plain'
    <<-EOS.gsub(/^\s+/, '')
      #{ChefRunDeck.app_name} is up and running!
      :config_file = #{ChefRunDeck.config_file}
      :cache_timeout = #{ChefRunDeck.cache_timeout}
      :params = #{params.inspect}
    EOS
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

      # => Instantiate the Default Client
      api_client

      # => Authorization
      # => get_auth
    end

    # => Clean Up
    after do
      # => Reset the API Client to Default Values
      ChefAPI.reset!
      # => Reset Authorization
      # => reset_auth
    end

    # => get '/state' do
    # =>   state.to_json
    # => end

    get '/state' do
      root.to_json
    end

    get '/list' do
      Node.list.to_json
    end

    # => Deliver Nodes the User is Authorized to Delete
    get '/list/:user' do |user|
      state.select { |n| n[:creator].casecmp(user) == 0 }.map { |n| n[:name] }.to_json
    end

    get '/node/:node' do |node|
      cache_control :public, max_age: 30
      node = Node.list.find { |n| n =~ /^#{node}$/i } if params['regex'] == '1'
      return false.to_json unless Node.exists?(node)
      return Node.fetch(node).to_json
    end

    # => Add Node to the State
    post '/add/:node/:user' do |node, user|
      (n = {}) && (n[:name] = node)
      n[:created] = DateTime.now
      n[:creator] = user
      n[:type] = params['type'] if params['type']
      update_state(n)
      state.to_json
    end

    # => Delete Node from the Chef Server
    post '/delete/:node' do |node|
      unless state.any? { |n| n[:name] == node }
        status 404
        return "#{node} not found".to_json
      end
      # => Delete the Node
      delete(node)
    end
  end
end
