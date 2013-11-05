require 'spec_helper'

describe Redis::Cacheable do
  it 'should have a version number' do
    Redis::Cacheable::VERSION.should_not be_nil
  end

  it 'should do something useful' do
    false.should be_true
  end
end
