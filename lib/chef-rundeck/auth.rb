# Encoding: UTF-8
# rubocop: disable LineLength
#
# Gem Name:: chef-rundeck
# Module:: Auth
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'chef-rundeck/config'
require 'chef-rundeck/util'
require 'digest'

module ChefRunDeck
  # => Authorization Module
  module Auth
    extend self

    #############################
    # =>    Authorization    <= #
    #############################

    # => This holds the Authorization State
    attr_accessor :auth

    def auth
      # => Define Authorization
      @auth ||= reset!
    end

    def reset!
      # => Reset Authorization
      @auth = { 'roles' => [] }
    end

    def parse(user = nil)
      # => Try to Find the User and their Authorization
      auth = Util.parse_json_config(Config.auth_file, false)
      return reset! unless auth && auth[user]
      @auth = auth[user]
    end

    def admin?
      # => Check if a User is an Administrator
      auth['roles'].any? { |x| x.casecmp('admin') == 0 }
    end

    def creator?(node)
      # => Grab the Node-State Object
      existing = State.find_state(node)
      return false unless existing
      # => Check if Auth User was the Node-State Creator
      existing[:creator].to_s.casecmp(Config.query_params['auth_user'].to_s) == 0
    end

    # => Validate the User's Authentication Key ## TODO: Use this, passthrough from a RunDeck Option Field
    def key?
      # => We store a SHA512 Hex Digest of the Key
      return false unless Config.query_params['auth_key']
      Digest::SHA512.hexdigest(Config.query_params['auth_key']) == auth['auth_key']
    end

    # => TODO: Project-Based Validation
    def project_admin?(project = nil)
      return false unless project.is_a?(Array)
      # => parse_auth.include?(user) && parse_auth[user]['roles'].any? { |r| ['admin', project].include? r.to_s.downcase }
      auth['roles'].any? { |r| ['admin', project].include? r.to_s.downcase }
    end

    # => Role-Based Administration
    def role_admin?(run_list = nil)
      return false unless run_list.is_a?(Array)
      # => This will Authorize Anyone if the RunList is Empty or the Chef Node does not exist!!!
      run_list.empty? || auth['roles'].any? { |role| run_list.any? { |r| r =~ /role\[#{role}\]/i } }
    end
  end
end
