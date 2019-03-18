require_relative 'spec_helper'

module Toil
  class ArgumentsSpec < Minitest::Spec
    let(:args) do
      Arguments.new([{ a: 1, b: 2, c: 3 }, 'Spork', q: 10]) do
        arg %i[x y z]
        attribute :key, 'value'
        uuid { SecureRandom.uuid }
        time { Time.now }
      end
    end

    let(:overrides) do
      [
        { a: 0, d: 4 },
        'Fork',
        { r: 11, time: 'Tomorrow maybe...' },
        %i[z y x]
      ]
    end

    it 'converts to an array' do
      a = args.to_a
      a.first.must_equal(a: 1, b: 2, c: 3)
      a[1].must_equal('Spork')
      atts = a[2]
      atts[:key].must_equal('value')
      atts[:q].must_equal(10)
      atts[:time].must_be_instance_of(Time)
      atts[:uuid].must_match_uuid
      a.last.must_equal(%i[x y z])
    end

    it 'overrides array values' do
      a = args.to_a(*overrides)
      a.first.must_equal(a: 0, b: 2, c: 3, d: 4)
      a[1].must_equal('Fork')
      atts = a[2]
      atts[:key].must_equal('value')
      atts[:q].must_equal(10)
      atts[:r].must_equal(11)
      atts[:time].must_equal('Tomorrow maybe...')
      atts[:uuid].must_match_uuid
      a.last.must_equal(%i[z y x])
    end

    it 'converts to attributes to a hash' do
      atts = args.to_h(r: 11)
      atts[:key].must_equal('value')
      atts[:q].must_equal(10)
      atts[:r].must_equal(11)
      atts[:time].must_be_instance_of(Time)
      atts[:uuid].must_match_uuid
    end

    it 'duplicates arguments' do
      dargs = args.dup { key('VALUE') }
      args.to_h[:key].must_equal('value')
      dargs.to_h[:key].must_equal('VALUE')
    end
  end
end
