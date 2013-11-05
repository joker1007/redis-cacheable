require 'spec_helper'

describe RedisCacheable::Connectable do
  describe "Class including RedisCacheable::Connectable" do
    describe ".redis" do
      it "call block with namespaced redis connection" do
        ConnectableObject.redis do |conn|
          expect(conn.namespace).to eq "connectable_object"
          conn.set("key", "value")
          expect(conn.get("key")).to eq "value"
        end
      end
    end

    describe "#redis" do
      it "call block with namespaced redis connection" do
        ConnectableObject.new.redis do |conn|
          expect(conn.namespace).to eq "connectable_object"
          conn.set("key", "value")
          expect(conn.get("key")).to eq "value"
        end
      end
    end
  end
end
