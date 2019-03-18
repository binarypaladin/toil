require_relative 'spec_helper'

module Toil
  class AttributesSpec < Minitest::Spec
    let(:atts) do
      Attributes.new(key: 'value') do
        uuid { SecureRandom.uuid }
      end
    end

    it 'initializes attributes' do
      h = atts.to_h
      h.keys.count.must_equal(2)
      h[:key].must_equal('value')
      h[:uuid].must_match_uuid
      atts.to_h[:uuid].wont_equal(h[:uuid])
    end

    it 'returns a single attribute' do
      v1 = atts[:uuid]
      v1.must_match_uuid

      v2 = atts[:uuid]
      v2.must_match_uuid

      v1.wont_equal(v2)
    end

    it 'adds dynamic attribute with missing method' do
      atts.other_uuid { SecureRandom.uuid }
      h = atts.to_h
      h.keys.count.must_equal(3)
      h[:uuid].must_match_uuid
      h[:other_uuid].must_match_uuid
      h[:uuid].wont_equal(h[:other_uuid])
    end

    it 'overrides attribute with static value' do
      atts.uuid('value')
      atts.to_h[:uuid].must_equal('value')
    end

    it 'overrides the final hash' do
      h = atts.to_h(key: 'VALUE')
      h[:uuid].must_match_uuid
      h[:key].must_equal('VALUE')
    end

    it 'duplicates attributes' do
      datts = atts.dup { key 'VALUE' }
      h = datts.to_h
      h[:uuid].must_match_uuid
      h[:key].must_equal('VALUE')
    end
  end
end
