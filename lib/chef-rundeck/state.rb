# Encoding: UTF-8
# rubocop: disable LineLength
#
# Gem Name:: chef-rundeck
# ChefRunDeck:: CLI
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'chef-rundeck/config'
require 'chef-rundeck/util'

module ChefRunDeck
  # => This is the State controller.  It manages State information
  module State
    extend self

    ##############################
    # =>   State Operations   <= #
    ##############################

    attr_accessor :state

    def state
      @state ||= Util.parse_json_config(Config.state_file) || []
    end

    def find_state(hash)
      state.detect { |h| h[:name].casecmp(hash[:name]) == 0 }
    end

    def update_state(hash) # rubocop: disable AbcSize
      # => Check if Node Already Exists
      existing = state.detect { |h| h[:name].casecmp(hash[:name]) == 0 }
      if existing # => Update the Existing Node
        state.delete(existing)
        audit_string = [DateTime.now, hash[:creator]].join(' - ')
        existing[:last_modified] = existing[:last_modified].is_a?(Array) ? existing[:last_modified].take(5).unshift(audit_string) : [audit_string]
        hash = existing
      end

      # => Update the State
      state.push(hash)

      # => Write Out the Updated State
      write_state
    end

    # => Add Node to the State
    def add_state(node, user, params)
      # => Create a Node Object
      (n = {}) && (n[:name] = node)
      n[:created] = DateTime.now
      n[:creator] = user
      n[:type] = params['type'] if params['type']
      update_state(n)
      state.to_json
    end

    def write_state
      # => Sort & Unique State
      state.sort_by! { |h| h[:name].downcase }.uniq!

      # => Write Out the Updated State
      Util.write_json_config(Config.state_file, state)
      # => Return the Updated State
      # => @state = state # => I don't think this is necessary
    end
  end
end
