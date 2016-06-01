# Encoding: UTF-8
#
# Gem Name:: chef-rundeck
# Helper:: Configuration
#
# Author: Eli Fatsi - https://www.viget.com/articles/easy-gem-configuration-variables-with-defaults
# Contributor: Brian Dwyer - Intelligent Digital Services
#

# => Configuration Helper Module
module Configuration
  #
  # => Provides a method to configure an Application
  # => Example:
  #      ChefRunDeck::Config.setup do |cfg|
  #        cfg.config_file = 'abc.json'
  #        cfg.app_name = 'GemBase'
  #      end
  #
  def setup
    yield self
  end

  def define_setting(name, default = nil)
    class_variable_set("@@#{name}", default)

    define_class_method "#{name}=" do |value|
      class_variable_set("@@#{name}", value)
    end

    define_class_method name do
      class_variable_get("@@#{name}")
    end
  end

  def delete_setting(name)
    remove_class_variable("@@#{name}")

    delete_class_method(name)
  rescue NameError # => Handle Non-Existent Settings
    return
  end

  private

  def define_class_method(name, &block)
    (class << self; self; end).instance_eval do
      define_method name, &block
    end
  end

  def delete_class_method(name)
    (class << self; self; end).instance_eval do
      undef_method name
    end
  end
end
