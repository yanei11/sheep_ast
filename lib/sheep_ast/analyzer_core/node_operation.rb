# typed: false
# frozen_string_literal:true

require_relative '../log'
require_relative '../exception'

# api public
module SheepAst
  # Aggregates User interface of sheep_ast library
  #
  # @api public
  module NodeOperation
    include Log
    include Exception
    extend T::Sig

    sig { returns(T::Array[NextCommand]) }
    def next_command
      if @focus.nil?
        ldebug 'Need forcus_on to point ast manager to use this function'
        return []
      end

      current_node(@focus).next_command
    end

    sig { params(name: String).returns(AnalyzerCore) }
    def focus_on(name)
      @focus = name
      return self
    end

    sig { params(dir: OperateNode).void }
    def move_focused_node(dir)
      move_node(@focus, dir)
    end

    sig { params(name: String, dir: OperateNode).void }
    def move_node(name, dir)
      a_stage = stage(name)
      case dir
      when OperateNode::Up
        parent_node = a_stage.current_node.parent_node
        node_info = NodeInfo.new
        node_info.node_id = T.must(parent_node).my_id
        a_stage.move_node(node_info)
      when OperateNode::Revert
        a_stage.move_committed_node
      when OperateNode::Commit
        a_stage.commit_node
      when OperateNode::Top
        node_info = NodeInfo.new
        node_info.node_id = 0 # root node id
        a_stage.move_node(node_info)
      end
    end

    private

    sig { params(name: String).returns(Node) }
    def current_node(name)
      return @stage_manager.stage_get(name).current_node
    end
  end
end
