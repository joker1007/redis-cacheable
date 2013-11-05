require 'spec_helper'

require 'active_record'

db_file = File.join(File.dirname(File.expand_path(__FILE__)), "..", "..", "test.sqlite3")

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: db_file
)

unless File.exists?(db_file)
  ActiveRecord::Migration.create_table :cacheable_active_records, force: true do |t|
    t.string :name
  end
end

class CacheableActiveRecord < ActiveRecord::Base
  include RedisCacheable::ActiveRecord
  redis_attrs :name
end

describe RedisCacheable::ActiveRecord do
  let(:record) { CacheableActiveRecord.create(name: "target") }

  before do
    CacheableActiveRecord.delete_all
  end

  describe "#cache_to_redis" do
    subject { record.cache_to_redis }

    it "cache redis_attrs data to redis" do
      record.cache_to_redis
      record.redis do |conn|
        expect(MultiJson.load(conn.get(record.id))).to eq({"name" => "target"})
      end
    end
  end

  describe ".find_from_redis" do
    subject { CacheableActiveRecord.find_from_redis(record.id) }

    before { record.cache_to_redis }

    it { should be_a(CacheableActiveRecord) }
    it { should be_persisted }

    it "has cached attributes" do
      expect(subject.name).to eq "target"
    end
  end

  describe ".cache_all" do
    subject { CacheableActiveRecord.cache_all }

    before do
      @record1 = CacheableActiveRecord.create(name: "target1")
      @record2 = CacheableActiveRecord.create(name: "target2")
      @record3 = CacheableActiveRecord.create(name: "target3")
    end

    it "caches all saved records" do
      subject
      CacheableActiveRecord.redis do |conn|
        expect(conn.get(@record1.id)).to be_present
        expect(conn.get(@record2.id)).to be_present
        expect(conn.get(@record3.id)).to be_present
      end
    end
  end
end
