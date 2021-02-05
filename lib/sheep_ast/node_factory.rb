# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require_relative 'messages'
require_relative 'node_buf'

module SheepAst
  # Factory object to create Node
  #
  # @api privte
  #
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
      @node_tag_db = {}
      create_id(@root_node)
      @root_node.my_node_factory = self
      init
    end

    # register rules for nodes
    sig {
      params(
        matches: T::Array[MatchBase],
        action: ActionBase,
        group: String
      ).void
    }
    def register_nodes(matches, action, group)
      init
      matches.each do |a_match|
        add(a_match, group)
      end
      add_action(action)
    end

    sig { params(match: MatchBase, group: String).void }
    def add(match, group)
      if match.parent_tag
        test = @node_tag_db[match.parent_tag]
        if test
          @__node = from_id(test)
        end
      end
      next_node = @__node.find(match.key)
      if next_node.nil?
        if @__node.my_action
          if !@__node.my_action.qualifier?
            lfatal @__node.my_action.warning
            missing_impl 'qualifier is needed for previous action'
          else
            @__node.my_action.need_qualify
          end
        end
        next_node = @__node.create(@__chain_num, match, group)
        @node_tag_db[match.node_tag] = next_node.my_id if match.node_tag
      end
      @__node = next_node
      @__chain_num += 1
    end

    sig {
      params(
        action: ActionBase
      ).void
    }
    def add_action(action)
      ldebug "action = #{action.name} is added to node id = #{@__node.my_id}"
      @__node.reg_action(action, nil)
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
