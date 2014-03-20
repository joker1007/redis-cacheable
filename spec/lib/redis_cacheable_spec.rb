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
  describe "Object including RedisCacheable" do
    describe "#cache_to_redis" do
      context "if redis_attrs is symbols" do
        subject { CacheableObject.new(id: 1, name: "target").cache_to_redis }

        it "cache redis_attrs data to redis" do
          subject
          expect(CacheableObject.find_from_redis(1)).to eq({"id" => 1, "name" => "target"})
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
  end
end
