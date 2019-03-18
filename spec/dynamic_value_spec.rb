require_relative 'spec_helper'

module Toil
  class DynamicValueSpec < Minitest::Spec
    it 'returns a static value' do
      dv = DynamicValue.new('value')
      assert dv.static?
      dv.call.must_equal('value')
    end

    it 'returns a dynamic value' do
      blk = proc { SecureRandom.uuid }
      dv = DynamicValue.new(blk)
      refute dv.static?

      v1 = dv.call
      v1.must_match_uuid

      v2 = dv.call
      v2.must_match_uuid
      v1.wont_equal(v2)

      dv = DynamicValue.new { SecureRandom.uuid }
      refute dv.static?
      dv.call.must_match_uuid
    end
  end
end
