require 'spec_helper'

class CacheableObject
  include RedisCacheable

  attr_reader :id, :name

  redis_key :id
  redis_attrs :id, :name

  def initialize(attrs)
    @id = attrs[:id]
    @name = attrs[:name]
  end
end

class ProcCacheableObject < CacheableObject
  redis_key :id
  redis_attrs ->(object) {
    object.id * 10
  }
end

class ProcKeyObject < CacheableObject
  redis_key ->(object) { "object_#{object.id}" }
end

class InheritBase < CacheableObject
  redis_key :name
end

class InheritChild < InheritBase; end

describe RedisCacheable do
  before do
    Redis.new.flushall
  end

  describe "Object including RedisCacheable" do
    describe "#cache_to_redis" do
      context "if redis_attrs is symbols" do
        subject { CacheableObject.new(id: 1, name: "target").cache_to_redis }

        it "cache redis_attrs data to redis" do
          subject
          expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
        end
      end

      context "if given expire option" do
        subject { CacheableObject.new(id: 1, name: "target").cache_to_redis(expire: 1) }

        it "cache redis_attrs data to redis and expired after given time" do
          subject
          sleep 1
          expect(CacheableObject.find_from_redis(1)).to be_nil
        end
      end

      context "if redis_attrs is proc" do
        subject { ProcCacheableObject.new(id: 1, name: "target").cache_to_redis }

        it "cache redis_attrs data to redis" do
          subject
          expect(ProcCacheableObject.find_from_redis(1)).to eq(10)
        end
      end

      context "if redis_key is proc" do
        subject { ProcKeyObject.new(id: 1, name: "target").cache_to_redis }

        it "use proc result as redis key" do
          subject
          expect(ProcKeyObject.find_from_redis("object_1")).to eq({"id" => 1, "name" => "target"})
        end
      end

      context "Inherit Test" do
        subject { InheritChild.new(id: 1, name: "target").cache_to_redis }

        it "use proc result as redis key" do
          subject
          expect(InheritChild.find_from_redis("target")).to eq({"id" => 1, "name" => "target"})
        end
      end
    end

    describe "#del_from_redis" do
      it "delete cached data from redis" do
        object = CacheableObject.new(id: 1, name: "target")
        object.cache_to_redis
        expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
        object.del_from_redis

        expect(CacheableObject.find_from_redis(1)).to be_nil
      end
    end

    describe "#expire_redis" do
      it "set expire time to cached data" do
        object = CacheableObject.new(id: 1, name: "target")
        object.cache_to_redis
        expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
        object.expire_redis(2)
        expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
        sleep 2
        expect(CacheableObject.find_from_redis(1)).to be_nil
      end
    end

    describe "#expireat_redis" do
      it "set expire time to cached data by unix_time" do
        object = CacheableObject.new(id: 1, name: "target")
        object.cache_to_redis
        expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
        object.expireat_redis((Time.now + 2).to_i)
        expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
        sleep 2
        expect(CacheableObject.find_from_redis(1)).to be_nil
      end
    end

    describe "#ttl_redis" do
      it "returns time to expire as second" do
        object = CacheableObject.new(id: 1, name: "target")
        object.cache_to_redis
        object.expire_redis(2)
        expect((1.0..2.0).cover?(object.ttl_redis)).to be_true
      end
    end
  end
end
