require 'toil'
require 'minitest/spec'
require 'minitest/autorun'
require 'securerandom'

module Minitest::Assertions
  UUID_PATTERN = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\Z/.freeze

  def assert_match_uuid(actual)
    assert match_uuid?(actual), %(Expected "#{actual}" to match a UUID)
  end

  def refute_match_uuid(actual)
    refute match_uuid?(actual), %(Expected "#{actual}" not to match a UUID)
  end

  private

  def match_uuid?(obj)
    obj.to_s =~ UUID_PATTERN
  end
end

Object.infect_an_assertion :assert_match_uuid, :must_match_uuid, :only_one_argument
