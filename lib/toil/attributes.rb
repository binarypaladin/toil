# frozen-string-literal: true

require 'toil/dynamic_value'

module Toil
  class Attributes
    def initialize(hash = {}, &blk)
      @attributes = hash.each_with_object({}) do |(k, v), h|
        h[k] = v.is_a?(DynamicValue) ? v : DynamicValue.new(v)
      end
      instance_eval(&blk) if block_given?
    end

    def method_missing(m, *args, &blk)
      __set__(m, args.first, &blk)
    end

    def dup(&blk)
      self.class.new(@attributes, &blk)
    end

    def to_h(overrides = {})
      @attributes.each_with_object({}) do |(k, v), h|
        h[k] = v.call unless overrides.key?(k)
      end.merge(overrides)
    end
    alias to_hash to_h

    def [](key)
      (v = @attributes[key]) && v.call
    end

    def __set__(key, value = nil, &blk)
      @attributes[key] = DynamicValue.new(value, &blk)
    end
  end
end
