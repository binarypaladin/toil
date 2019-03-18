# frozen-string-literal: true

require 'toil/prototype'

module Toil
  class << self
    def call(prototype_name, *overrides)
      self[prototype_name].call(*overrides)
    end
    alias create call

    def [](prototype_name)
      Prototype[prototype_name]
    end

    def register(prototype_name, obj = nil, &blk)
      Prototype.register(prototype_name, obj, &blk)
    end

    def to_a(prototype_name, *overrides)
      self[prototype_name].to_a(*overrides)
    end
    alias args to_a
    alias arguments to_a

    def to_h(prototype_name, overrides = {})
      self[prototype_name].to_h(overrides)
    end
    alias atts to_h
    alias attributes to_h
    alias params to_h
  end
end
