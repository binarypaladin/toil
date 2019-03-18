require_relative 'spec_helper'

module Toil
  class PrototypeSpec < Minitest::Spec
    let(:attributes) { { a: 'a', b: 'b', c: 'c' } }

    let(:constructor) do
      ->(h) { h.each_with_object({}) { |(k, v), nh| nh[k] = v.to_s.upcase } }
    end

    let(:prototype) do
      Prototype.new(constructor, attributes) do
        before_create { |atts, *| atts[:x] = atts[:a] }
        after_create { |obj| obj[:d] = obj[:x] }
      end
    end

    it 'creates an object' do
      prototype.call.must_equal(a: 'A', b: 'B', c: 'C', d: 'A', x: 'A')
    end

    it 'overrides values' do
      prototype.call(a: 'z').must_equal(a: 'Z', b: 'B', c: 'C', d: 'Z', x: 'Z')
    end

    it 'duplicates a prototype' do
      prototype.dup do
        before_create { |args| args[0] = { z: 'z' } }
      end.call.must_equal(z: 'Z', d: nil)

      prototype.dup do
        a 'z'
        before_create { |atts, *| atts.delete(:c) }
        after_create { |obj| obj[:d] = 'd' }
      end.(y: 'y').must_equal(a: 'Z', b: 'B', d: 'd', y: 'Y', x: 'Z')

      prototype.call.must_equal(a: 'A', b: 'B', c: 'C', d: 'A', x: 'A')
    end

    it 'returns an array of arguments' do
      prototype.to_a.must_equal([{ a: 'a', b: 'b', c: 'c', x: 'a' }])
      prototype.to_a(a: 'z', x: 'x')
               .must_equal([{ a: 'z', b: 'b', c: 'c', x: 'z' }])
    end

    it 'returns a hash of arguments' do
      prototype.to_h.must_equal(a: 'a', b: 'b', c: 'c', x: 'a')
      prototype.to_h(a: 'z', x: 'x').must_equal(a: 'z', b: 'b', c: 'c', x: 'z')
    end

    it 'only allows constructors that respond to `call`' do
      -> { Prototype.new('x') }.must_raise(ArgumentError)
    end

    it 'registers a new prototype' do
      -> { Prototype[:__reg_test_1__] }.must_raise(Prototype::NotRegistered)
      Prototype.register(:__reg_test_1__, constructor)
      Toil.to_a(:__reg_test_1__).to_a.must_equal([])
      -> { Prototype.register(:__reg_test_1__, constructor) }
        .must_raise(Prototype::AlreadyRegistered)
      Prototype[:__reg_test_1__].(a: 'a').must_equal(a: 'A')

      Toil.register(:__reg_test_2__, :__reg_test_1__) do
        arg({})

        before_create do |atts, *|
          atts.each { |k, v| atts[k] = "#{v}x" }
        end

        after_create { |obj| obj[:x] = 'x' }
      end

      Toil.(:__reg_test_2__, a: 'a').must_equal(a: 'AX', x: 'x')
      Toil.to_a(:__reg_test_2__, b: 'b').must_equal([{ b: 'bx' }])
      Toil.to_h(:__reg_test_2__, b: 'b').must_equal(b: 'bx')
    end
  end
end
