require 'active_support/core_ext/module'
require 'active_support/concern'
require 'redis_cacheable/configuration'
require 'connection_pool'
require 'redis-namespace'

module RedisCacheable
  module Connectable
    mattr_accessor :redis_connection

    extend ActiveSupport::Concern

    module ClassMethods
      def redis_namespace
        config = RedisCacheable::Configuration.config
        namespace = [to_s.underscore]
        namespace.unshift config.namespace_prefix if config.namespace_prefix
        namespace.join("_")
      end

      def redis(&blk)
        raise ArgumentError.new("Need block") unless blk

        unless Connectable.redis_connection
          config = RedisCacheable::Configuration.config
          Connectable.redis_connection = ConnectionPool.new(size: config.pool_size, timeout: config.timeout) {
            Redis.new(host: config.host, port: config.driver, driver: config.driver.to_sym)
          }
        end

        Connectable.redis_connection.with do |conn|
          namespaced_redis = Redis::Namespace.new(redis_namespace, redis: conn)
          blk.call(namespaced_redis)
        end
      end
    end

    def redis(&blk)
      raise ArgumentError.new("Need block") unless blk

      self.class.redis(&blk)
    end
  end
end
