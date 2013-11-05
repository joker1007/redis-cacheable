require 'active_support/concern'
require 'active_support/core_ext/class'
require 'multi_json'

require 'redis_cacheable/version'
require 'redis_cacheable/configuration'
require 'redis_cacheable/connectable'

module RedisCacheable
  extend ActiveSupport::Concern
  include Connectable

  module ClassMethods
    def redis_key(key)
      @__redis_cache_key__ = key
    end

    def redis_attrs(*attributes)
      if attributes.first.is_a?(Proc)
        @__redis_cache_attrs__ = attributes.first
      else
        @__redis_cache_attrs__ = attributes.flatten
      end
    end

    # TODO: ActiveRecord拡張として切り出す
    def cache_all
      find_each do |record|
        record.cache_to_redis
      end
      redis.save
    end

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
      if respond_to?(:as_json)
        options = __redis_cache_attrs__.present? ? {only: __redis_cache_attrs__} : {}
        as_json(options)
      else
        __redis_cache_attrs__.each_with_object({}) do |attr, hash|
          hash[attr] = send(attr)
        end
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
