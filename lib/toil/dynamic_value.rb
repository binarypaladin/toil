# frozen-string-literal: true

module Toil
  class DynamicValue
    def initialize(value = nil, &blk)
      @static = false
      @proc =
        if block_given?
          blk
        elsif value.is_a?(Proc)
          value
        else
          @static = true
          proc { value }
        end
    end

    def call
      @proc.call
    end

    def static?
      @static
    end
  end
end
