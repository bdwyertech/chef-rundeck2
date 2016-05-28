# Encoding: UTF-8
# rubocop: disable LineLength
#
# Gem Name:: chef-rundeck
# ChefRunDeck:: Util
#
# Copyright (C) 2016 Brian Dwyer - Intelligent Digital Services
#
# All rights reserved - Do Not Redistribute
#

require 'json'

module ChefRunDeck
  # => Utility Methods
  module Util
    extend self

    ########################
    # =>    File I/O    <= #
    ########################

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
  end
end
