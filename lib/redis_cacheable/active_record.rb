require 'redis_cacheable'

module RedisCacheable
  module ActiveRecord
    extend ActiveSupport::Concern
    include ::RedisCacheable

    module ClassMethods
      def find_from_redis(key)
        if data = super(key)
          instantiate(data)
        end
      end

      def cache_all
        find_each do |record|
          record.cache_to_redis
        end

        redis do |conn|
          conn.save
        end
      end
    end
  end
end
