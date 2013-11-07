require 'redis_cacheable'

# Specialized for ActiveRecord
module RedisCacheable
  module ActiveRecord
    extend ActiveSupport::Concern
    include ::RedisCacheable

    module ClassMethods
      # @param [Object] key
      # @return [ActiveRecord::Base] ActiveRecord instantiated object
      def find_from_redis(key)
        if data = super(key)
          instantiate(data)
        end
      end

      # cache all persisted records
      # @return [void]
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
