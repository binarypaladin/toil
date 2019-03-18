# frozen-string-literal: true

require 'toil/arguments'

module Toil
  class Prototype
    CALLBACKS = %i[after_create before_create].freeze
    NO_ATTS_MSG = 'There are no attribute arguments for this prototype.'.freeze
    AlreadyRegistered = Class.new(ArgumentError)
    NoAttributesDefined = Class.new(RuntimeError)
    NotRegistered = Class.new(ArgumentError)

    @@registry = {}

    class << self
      def [](key)
        raise NotRegistered, "`:#{key}` is not a registered prototype" unless
          @@registry.key?(key)
        @@registry[key]
      end

      def register(key, obj = nil, &blk)
        key = key.to_sym
        raise AlreadyRegistered, "`:#{key}` has already been registered" if
          @@registry.key?(key)

        @@registry[key] = obj.is_a?(Symbol) ? self[obj].dup(&blk) : new(obj, &blk)
      end
    end

    def initialize(constructor, arguments = [], callbacks = {}, &blk)
      @constructor = __constructor__(constructor)
      @arguments = __arguments__(arguments)
      @callbacks = __callbacks__(callbacks)
      instance_eval(&blk) if block_given?
    end

    def call(*overrides)
      __exec_callbacks__(:after_create, @constructor.(*to_a(*overrides)))
    end

    def method_missing(m, *args, &blk)
      @arguments.public_send(m, *args, &blk)
    end

    def dup(&blk)
      self.class.new(@constructor, @arguments, @callbacks, &blk)
    end

    def to_a(*overrides)
      __exec_callbacks__(:before_create, @arguments.to_a(*overrides))
    end
    alias to_ary to_a

    def to_h(overrides = {})
      raise NoAttributesDefined, NO_ATTS_MSG unless (at = @arguments.attributes_at)
      args = @arguments.to_a
      args[at].merge!(overrides)
      __exec_callbacks__(:before_create, args)[at]
    end
    alias to_hash to_h

    CALLBACKS.each do |key|
      define_method(key) { |&blk| @callbacks[key] += [blk] }
    end

    private

    def __arguments__(args)
      args.is_a?(Arguments) ? args.dup : Arguments.new(args)
    end

    def __callbacks__(callbacks)
      CALLBACKS.each_with_object({}) { |k, h| h[k] = [] }.merge(callbacks)
    end

    def __constructor__(obj)
      raise ArgumentError, 'Object does not respond to `call`' unless obj.respond_to?(:call)
      obj
    end

    def __exec_callbacks__(key, args)
      @callbacks[key].each { |clbk| clbk.(args) }
      args
    end
  end
end
