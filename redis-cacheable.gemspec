# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_cacheable/version'

Gem::Specification.new do |spec|
  spec.name          = "redis-cacheable"
  spec.version       = RedisCacheable::VERSION
  spec.authors       = ["joker1007"]
  spec.email         = ["kakyoin.hierophant@gmail.com"]
  spec.summary       = %q{Concern style helper of caching object to Redis}
  spec.description   = %q{Concern style helper of caching object to Redis}
  spec.homepage      = "https://github.com/joker1007/redis-cacheable"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 3"
  spec.add_dependency "redis"
  spec.add_dependency "redis-namespace"
  spec.add_dependency "connection_pool"
  spec.add_dependency "multi_json"

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "oj"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "mock_redis"
end
