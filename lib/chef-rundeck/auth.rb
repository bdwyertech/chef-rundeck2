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

module ChefRunDeck
  # => Authorization Module
  module Auth
    extend self

    #############################
    # =>    Authorization    <= #
    #############################

    def initialize
      # => Define Authorization
      @auth ||= (auth = {}) && (auth['roles'] = [])
    end

    # => This holds the Authorization State
    attr_accessor :auth

    def reset!
      # => Reset Authorization
      @auth = (auth = {}) && (auth['roles'] = [])
    end

    def parse_auth
      # => parse_json_config(ChefRunDeck.auth_file)
      authfile = Config.auth_file
      File.mtime(auth_file) if File.exist?(auth_file)
      # => File.open('/path/to/file.extension', 'w') {|f| f.write(Marshal.dump(m)) }
      # => { token: 'abc123' }
    end

    def valid?(user, project = nil, key = nil)
      parse_auth.include?(user) && parse_auth[user]['roles'].any? { |r| ['admin', project].include? r }
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
  end
end
