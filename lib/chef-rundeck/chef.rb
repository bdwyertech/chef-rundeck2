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
require 'chef-rundeck/config'

module ChefRunDeck
  # => This is the Chef module.  It interacts with the Chef server
  module Chef # rubocop: disable ModuleLength
    extend self
    # => Include Modules
    include ChefAPI::Resource

    #########################
    # =>     ChefAPI     <= #
    #########################

    def api_client
      # => Configure a Chef API Client
      ChefAPI.endpoint = Config.chef_api_endpoint
      ChefAPI.client = Config.chef_api_client
      ChefAPI.key = Config.chef_api_client_key
    end

    def admin_api_client
      # => Configure an Administrative Chef API Client
      ChefAPI.endpoint = Config.chef_api_endpoint
      ChefAPI.client = Config.chef_api_admin
      ChefAPI.key = Config.chef_api_admin_key
    end

    def reset!
      # => Reset the Chef API Configuration
      ChefAPI.reset!
      # => Clear Transient Configuration
      Config.clear(:rundeck)
    end

    # => Get Node
    def get_node(node, casecomp = false)
      node = Node.list.find { |n| n =~ /^#{node}$/i } if casecomp
      return false unless Node.exists?(node)
      Node.fetch(node)
    end

    # => Return Array List of Nodes
    def list
      Node.list
    end

    # => Return a Node's Run List
    def run_list(node)
      return [] unless Node.exists?(node)
      Node.fetch(node).run_list
    end

    # => Delete a Node Object
    def delete(node)
      # => Make sure the Node Exists
      return 'Node not found on Chef Server' unless Node.exists?(node)

      # => Initialize the Admin API Client Settings
      admin_api_client

      # => Delete the Client & Node Object
      Client.delete(node)
      Node.delete(node)
      'Client/Node Deleted from Chef Server'
    end

    #############################
    # =>  Resource Provider  <= #
    #############################

    #
    # => Try to Parse Project-Specific Settings
    #
    def project_settings(project)
      settings = Util.parse_json_config(Config.projects_file, false)
      return {} unless settings && settings[project]
      settings[project]
    end

    #
    # => Construct Query-Specific Configuration
    #
    def transient_settings # rubocop: disable AbcSize
      # => Initialize any Project-Specific Settings
      project = project_settings(Config.query_params['project'])

      # => Build the Configuration
      cfg = {}
      cfg[:username] = Config.query_params['username'] || project['username'] || Config.rd_node_username
      cfg[:pattern] = Config.query_params['pattern'] || project['pattern'] || '*:*'
      cfg[:extras] = Util.serialize_csv(Config.query_params['extras']) || project['extras']

      # => Make the Settings Available via the Config Object
      Config.add(rundeck: cfg)
    end

    #
    # => Base Search Filter Definition
    #
    def default_search_filter
      {
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
    end

    #
    # => Parse Additional Filter Elements
    #
    # => Default Elements can be removed by passing them in here as null or empty
    #
    def search_filter_additions
      attribs = {}
      Array(Config.rundeck[:extras]).each do |attrib|
        attribs[attrib.to_sym] = [attrib]
      end
      # => Return the Custom Filter Additions Hash
      attribs
    end

    #
    # => Construct the Search Filter
    #
    def search_filter
      # => Merge the Default Filter with Additions
      default_search_filter.merge(search_filter_additions).reject { |_k, v| v.nil? || String(v).empty? }
    end

    #
    # => Define Extra Attributes for Resource Return
    #
    def custom_attributes(node)
      attribs = {}
      Array(Config.rundeck[:extras]).each do |attrib|
        attribs[attrib.to_sym] = node[attrib].inspect
      end
      # => Return the Custom Attributes Hash
      attribs
    end

    def search(pattern = '*:*') # rubocop: disable AbcSize
      # => Initialize the Configuration
      transient_settings

      # => Pull in the Pattern
      pattern = Config.rundeck[:pattern]

      # => Execute the Chef Search
      result = PartialSearch.query(:node, search_filter, pattern, start: 0)

      # => Custom-Tailor the Resulting Objects
      result.rows.collect do |node|
        {
          nodename: node['name'],
          hostname: node['fqdn'] || node['hostname'],
          osArch: node['kernel_machine'],
          osFamily: node['platform'],
          osName: node['platform'],
          osVersion: node['platform_version'],
          description: node['name'],
          roles: node['roles'].join(','),
          recipes: node['recipes'].join(','),
          tags: [node['roles'], node['recipes'], node['chef_environment'], node['tags']].flatten.join(','),
          environment: node['chef_environment'],
          editUrl: ::File.join(Config.chef_api_endpoint, 'nodes', node['name']),
          username: Config.rundeck[:username]
        }.merge(custom_attributes(node)).reject { |_k, v| v.nil? || String(v).empty? }
      end
    end
  end
end
