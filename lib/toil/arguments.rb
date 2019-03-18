# frozen-string-literal: true

require 'toil/attributes'

module Toil
  class Arguments
    def initialize(args, &blk)
      @args = __array__(args).map { |v| __arg__(v) }
      __find_attributes__
      instance_eval(&blk) if block_given?
    end

    def method_missing(m, *args, &blk)
      attribute(m, args.first, &blk)
    end

    def arg(value = nil, &blk)
      arg_at(@args.size, value, &blk)
    end

    def arg_at(index, value = nil, &blk)
      @args[index] = __arg__(value, &blk)
      __find_attributes__
      @args[index]
    end

    def attribute(key, value = nil, &blk)
      @attributes || arg({})
      @attributes.__set__(key, value, &blk)
    end

    def attributes_at
      @args.each_with_index { |v, i| return i if v == @attributes }
      nil
    end

    def dup(&blk)
      self.class.new(@args, &blk)
    end

    def [](key)
      @attributes[key]
    end

    def to_a(*overrides)
      @args.each_with_index.map do |a, i|
        if overrides.size > i
          __merge_or_override__(overrides[i], a)
        elsif a.is_a?(Attributes)
          a.to_h
        else
          a.call
        end
      end + Array(overrides[(@args.size)..-1])
    end
    alias to_ary to_a

    def to_h(overrides = {})
      @attributes.to_h(overrides)
    end
    alias to_hash to_h

    private

    def __arg__(arg, &blk)
      return DynamicValue.new(&blk) if block_given?

      case arg
      when Attributes
        arg.dup
      when DynamicValue
        arg
      when Hash
        Attributes.new(arg)
      else
        DynamicValue.new(arg)
      end
    end

    def __array__(args)
      args.is_a?(Array) ? args : [args]
    end

    def __find_attributes__
      @attributes ||= @args.reverse.find { |v| v.is_a?(Attributes) }
    end

    def __merge_or_override__(override, arg)
      return arg.to_h(override) if override.is_a?(Hash) && arg.is_a?(Attributes)
      override
    end
  end
end
