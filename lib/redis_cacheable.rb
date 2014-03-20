require 'active_support/concern'
require 'active_support/core_ext/class'
require 'multi_json'

require 'redis_cacheable/version'
require 'redis_cacheable/configuration'
require 'redis_cacheable/connectable'

# Usage:
#
# class CacheableObject
#   include RedisCacheable
#
#   attr_reader :id, :name
#
#   redis_key :id
#   redis_attrs :id, :name
#
#   def initialize(attrs)
#     @id = attrs[:id]
#     @name = attrs[:name]
#   end
# end
#
# CacheableObject.new(id: 1, name: "object").cache_to_redis
# CacheableObject.find_from_redis(1) # => {"id" => 1, "name" => "target"}
module RedisCacheable
  extend ActiveSupport::Concern
  include Connectable

  module ClassMethods
    def inherited(subclass)
      subclass.instance_variable_set("@__redis_cache_key__", @__redis_cache_key__)
      subclass.instance_variable_set("@__redis_cache_attrs__", @__redis_cache_attrs__)
    end

    # @param [Symbol || Proc] key used by redis.set method
    # @example If Symbol, param is method name
    #   redis_key :uuid
    # @example If Proc
    #   redis_key ->(user) {"#{user.id}_{user.email}"}
    def redis_key(key)
      @__redis_cache_key__ = key
    end

    # @param [Array<Symbol> || Proc] attributes
    # @example If Symbols, param is method name
    #   redis_attrs :uuid, :name, :email
    # @example If Proc, proc must return JSON serializable object
    #   redis_attrs ->(user) { {id: user.id, name: user.name, email: user.email} }
    def redis_attrs(*attributes)
      if attributes.first.is_a?(Proc)
        @__redis_cache_attrs__ = attributes.first
      else
        @__redis_cache_attrs__ = attributes.flatten
      end
    end

    # @param [Object] key JSON
    # @return [String || Number || Array || Hash]
    def find_from_redis(key)
      redis do |conn|
        json = conn.get(key)
        return nil unless json

        MultiJson.load(json)
      end
    end

    # @private
    # for internal use
    def __redis_cache_key__
      @__redis_cache_key__ || :id
    end

    # @private
    # for internal use
    def __redis_cache_attrs__
      @__redis_cache_attrs__ || []
    end
  end

  def cache_to_redis
    redis do |conn|
      conn.set(redis_cache_key, MultiJson.dump(redis_cache_data))
    end
  end

  private
  def redis_cache_key
    case __redis_cache_key__
    when Proc
      __redis_cache_key__.call(self)
    when Symbol
      send(__redis_cache_key__)
    end
  end

  def redis_cache_data
    case __redis_cache_attrs__
    when Proc
      __redis_cache_attrs__.call(self)
    when Array
      __redis_cache_attrs__.each_with_object({}) do |attr, hash|
        hash[attr] = send(attr)
      end
    end
  end

  def __redis_cache_key__
    self.class.__redis_cache_key__
  end

  def __redis_cache_attrs__
    self.class.__redis_cache_attrs__
  end
end
