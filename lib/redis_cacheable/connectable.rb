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

        connection = __ensure_redis_connection__

        case connection
        when ConnectionPool
          connection.with do |conn|
            blk.call(__wrap_namespace__(conn))
          end
        when Redis
          blk.call(__wrap_namespace__(connection))
        else
          raise "Not redis connection"
        end
      end

      private
      def __ensure_redis_connection__
        unless Connectable.redis_connection
          config = RedisCacheable::Configuration.config
          Connectable.redis_connection = ConnectionPool.new(size: config.pool_size, timeout: config.timeout) {
            Redis.new(host: config.host, port: config.port, driver: config.driver.to_sym)
          }
        end

        Connectable.redis_connection
      end

      def __wrap_namespace__(connection)
        Redis::Namespace.new(redis_namespace, redis: connection)
      end
    end

    def redis(&blk)
      raise ArgumentError.new("Need block") unless blk

      self.class.redis(&blk)
    end
  end
end
