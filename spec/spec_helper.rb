$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'redis_cacheable'
require 'redis_cacheable/active_record'
require 'redis'
require 'mock_redis'

require 'coveralls'
Coveralls.wear!

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'

  config.before(:each) do
    Redis.stub(:new).with(any_args) { MockRedis.new }
  end
end

class ConnectableObject
  include RedisCacheable::Connectable
end
