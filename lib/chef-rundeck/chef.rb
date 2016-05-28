# Encoding: UTF-8
# rubocop: disable LineLength, MethodLength
#
# Gem Name:: chef-rundeck
# Module:: Chef
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'chef-api'

module ChefRunDeck
  # => This is the Chef module.  It interacts with the Chef server
  module Chef
    extend self
    # => Include Modules
    include ChefAPI::Resource

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

    def reset!
      # => Reset the Chef API Configuration
      ChefAPI.reset!
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
    # =>  Resource Provider  <= #
    #############################

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
      result.rows # => .first['hostname']
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

    # => Get Node
    def get_node(node, casecomp = false)
      node = Node.list.find { |n| n =~ /^#{node}$/i } if casecomp
      return false unless Node.exists?(node)
      Node.fetch(node)
    end

    # => List Nodes
    def list
      Node.list
    end
  end
end

# => Chef Search
# => result = PartialSearch.query(:node, filter, '*:*', start: 1)
# => nodes = result.rows.collect do |node|
# =>   # => Custom-Tailor the Resulting Objects
# =>   {
# =>     'name' => node['name'],
# =>     'chef_environment' => node['chef_environment'],
# =>     'run_list' => node['run_list'],
# =>     'recipes' => node['run_list'] ? node['run_list']['recipes'] : nil,
# =>     'roles' => node['run_list'] ? node['run_list']['roles'] : nil,
# =>     'fqdn' => node['fqdn'],
# =>     'hostname' => node['hostname'],
# =>     'kernel_machine' => node['kernel'] ? node['kernel']['machine'] : nil,
# =>     'kernel_os' => node['kernel'] ? node['kernel']['os'] : nil,
# =>     'platform' => node['platform'],
# =>     'tags' => node['tags']
# =>   }
# => end
# => 
# => resources = result.rows.collect do |node|
# =>   custom = ['a', 'b', 'c'].map do |attribute|
# =>       { "#{attribute}" => node['attribute'] }
# =>   end
# =>   {
# =>     nodename: node['fqdn'],
# =>     hostname: node['fqdn'] || node['hostname'],
# =>     username: 'rundeck',
# =>     osArch: node['kernel_machine'],
# =>     osFamily: node['platform'],
# =>     osName: node['platform'],
# =>     osVersion: node['platform_version'],
# =>     description: node['name'],
# =>     roles: node['roles'].join(','),
# =>     recipes: node['recipes'].join(','),
# =>     tags: [node['roles'], node['recipes'], node['chef_environment'], node['tags']].flatten.join(','),
# =>     environment: node['chef_environment'],
# =>     editUrl: '',
# =>   }
# => end
