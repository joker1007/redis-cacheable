# redis-cacheable
[![Build Status](https://travis-ci.org/joker1007/redis-cacheable.png?branch=master)](https://travis-ci.org/joker1007/redis-cacheable)
[![Coverage Status](https://coveralls.io/repos/joker1007/redis-cacheable/badge.png?branch=master)](https://coveralls.io/r/joker1007/redis-cacheable?branch=master)
[![Code Climate](https://codeclimate.com/github/joker1007/redis-cacheable.png)](https://codeclimate.com/github/joker1007/redis-cacheable)

It is concern style redis caching helper.
It makes very easy to cache object.

## Installation

Add this line to your application's Gemfile:

    gem 'redis-cacheable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-cacheable

## Usage

### Plain Object

```ruby
class MyObject
  include RedisCacheable

  attr_reader :id, :name

  redis_key   :id          # optional (default: :id)
  redis_attrs :id, :name # method names

  def initialize(attributes)
    @id = attributes[:id]
    @name = attributes[:name]
  end
end

class ProcObject < MyObject
  redis_attrs ->(obj) { obj.id * 10 } # can give proc
end
```

```ruby
my_object = MyObject.new(id: 1, name: "my_object")
my_object.cache_to_redis # KEY = my_object.id, VALUE = MultiJson.dump({"id" => my_object.id, "name" => my_object.name})

MyObject.find_from_redis(1) # => {"id" => 1, "name" => "my_object"}

proc_object = ProcObject.new(id: 1, name: "proc_object")
proc_object.cache_to_redis # different namespace with MyObject
ProcObject.find_from_redis(1) # => 10
```

### ActiveRecord

If you use ActiveRecord, can include more specialized module.

```ruby
# id: integer
# name: string
# rate: float

class MyRecord < ActiveRecord::Base
  include RedisCacheable::ActiveRecord
  redis_attrs :id, :name, :rate # method names
end
```

```ruby
record = MyRecord.create(name: "my_record", rate: 4.5)
record.cache_to_redis
MyRecord.find_from_redis(record.id) #=> #<MyRecord id: 1, name: "my_record", rate: "4.5">

MyRecord.cache_all # cache all records
```

## Configuration

```ruby
RedisCacheable::Configuration.configure do |config|
  config.host = "10.0.0.1"          #  redis host (default: "localhost")
  config.port = 6380                #  redis port (default: 6379)
  config.driver = :hiredis          #  redis port (default: :ruby)
  config.namespace_prefix = "myapp" #  see below.
  config.pool_size = 10             #  connection pool size (default: 5)
  config.timeout = 10               #  timeout seconds (default: 5)
end
```

`config.namespace_prefix` is useful, If multi application use same redis.

```ruby
RedisCacheable.configure do |config|
  config.namespace_prefix = "myapp" #  see below.
end

class MyObject
  include RedisCacheable

  # ...
end

# MyObject redis namespace is "myapp_my_object"
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
