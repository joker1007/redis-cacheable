require 'spec_helper'

describe RedisCacheable::Configuration do
  describe ".config" do
    subject { described_class.config }

    it "has initial config data" do
      expect(subject.host).to eq "localhost"
      expect(subject.port).to eq 6379
      expect(subject.driver).to eq :ruby
      expect(subject.pool_size).to eq 5
      expect(subject.timeout).to eq 5
    end
  end
end
