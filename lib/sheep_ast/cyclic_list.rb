# typed: strict
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'

module SheepAst
  # Factory of factories
  #
  # @api private
  #
  class CyclicList
    extend T::Sig
    include Log
    include Exception

    sig { params(history: Integer).void }
    def initialize(history)
      super()
      @history = history
      @live_node = {}
      @node_id = 0
    end

    sig { params(val: T.untyped).void }
    def put(val)
      ldebug? and ldebug "#{val.inspect} is put"

      new = CyclicNode.new
      new.value = val
      new.my_id = @node_id
      @live_node[@node_id] = new

      @old = @last
      @last = new
      @last.next = @old

      @node_id += 1
      if @node_id >= @history
        @node_id = 0
        @once_over = true
      end
    end

    sig { returns(T.untyped) }
    def last
      return history(0)
    end

    sig { params(history: Integer).returns(T.untyped) }
    def history(history)
      if history >= @history
        lwarn 'Input [0..history) value' and return nil
      end

      node_id = @last.my_id

      # Note:
      # Search algorithm could be several ways.
      # Here get history from hash map is applied for O(N) operation
      #
      node = nil
      search_id = node_id - history
      if search_id.negative?
        search_id = history + search_id
      end
      node = @live_node[search_id]

      # (history - 1).times do
      #   node = node&.next
      # end
      #
      ldebug? and ldebug "#{node.value.inspect} is got"

      if node.nil?
        return nil
      else
        node.value
      end
    end
  end

  class CyclicNode
    attr_accessor :next
    attr_accessor :value
    attr_accessor :my_id
  end
end
