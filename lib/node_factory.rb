# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require_relative 'messages'
require_relative 'node_buf'

module Sheep
  # Node fatiory
  class NodeFactory
    extend T::Sig
    include Log
    include Exception
    include FactoryBase

    sig { returns(Node) }
    attr_reader :root_node

    sig { void }
    def initialize
      super()
      @root_node = Node.new(0)
      create_id(@root_node)
      @root_node.my_node_factory = self
      init
    end

    # register rules for nodes
    sig {
      params(
        matches: T::Array[MatchBase],
        action: ActionBase,
        group: String,
        qualifier: T.nilable(
          T.proc.params(
            arg0: T::Array[String]
          ).returns(T::Boolean)
        )
      ).void
    }
    def register_nodes(matches, action, group, qualifier = nil)
      init
      matches.each do |a_match|
        add(a_match, group)
      end
      add_action(action, qualifier)
    end

    sig { params(match: MatchBase, group: String).void }
    def add(match, group)
      next_node = @__node.find(match.key)
      if next_node.nil?
        if @__node.my_action && !@__node.my_action&.qualifier?
          lfatal @__node.my_action.warning
          missing_impl 'qualifier is needed for previous action'
        end
        next_node = @__node.create(@__chain_num, match, group)
      end
      @__node = next_node
      @__chain_num += 1
    end

    sig {
      params(
        action: ActionBase,
        qualifier: T.nilable(T.proc.params(
          a1: T::Array[String]
        ).returns(T::Boolean))
      ).void
    }
    def add_action(action, qualifier = nil)

      ldebug "action = #{action.name} is added to node id = #{@__node.my_id}"
      @__node.reg_action(action, qualifier)
    end

    sig { void }
    def init
      @__node = @root_node
      @__chain_num = 1
    end

    # find next node from the root node
    sig { params(data: AnalyzeData).returns(NodeInfo) }
    def find_from_root_node(data)
      return root_node.find_next_node(data)
    end

    # dump ast tree
    sig { params(logs: Symbol).void }
    def dump_tree(logs)
      NodeBuf.buffer_init
      @root_node.node_buffer.save_tree_from_here
      @root_node.node_buffer.dump_buffer(logs)
    end
  end
end
