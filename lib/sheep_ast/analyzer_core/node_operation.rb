# typed:true
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

    # TBD
    class Direction < T::Enum
      include Log
      include Exception

      enums do
        Top = new
        Up = new
        Goto = new
        Revert = new
        Commit = new
      end
    end

    sig { params(name: String).returns(T::Array[NextCommand]) }
    def next_command(name)
      current_node(name).next_command
    end

    sig { params(name: String, dir: Direction).void }
    def move_node(name, dir)
      a_stage = stage(name)
      case dir
      when Direction::Up
        parent_node = a_stage.current_node.parent_node
        node_info = NodeInfo.new
        node_info.node_id = T.must(parent_node).my_id
        a_stage.move_node(node_info)
      when Direction::Revert
        a_stage.move_committed_node
      when Direction::Commit
        a_stage.commit_node
      when Direction::Top
        node_info = NodeInfo.new
        node_info.node_id = 0 # root node id
        a_stage.move_node(node_info)
      end
    end

    private

    sig { params(name: String).returns(Stage) }
    def stage(name)
      return @stage_manager.stage_get(name)
    end

    sig { params(name: String).returns(Node) }
    def current_node(name)
      return @stage_manager.stage_get(name).current_node
    end
  end
end
