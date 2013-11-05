require 'singleton'
require 'active_support/configurable'

module RedisCacheable
  class Configuration
    include Singleton
    include ActiveSupport::Configurable

    config_accessor :host, :port, :driver, :namespace_prefix, :pool_size, :timeout

    config.host ||= "localhost"
    config.port ||= 6379
    config.driver ||= :ruby
    config.pool_size ||= 5
    config.timeout ||= 5
  end
end
