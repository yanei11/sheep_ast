# typed: true
# frozen_string_literal: true

require_relative 'exception'
require_relative 'log'
require_relative 'sheep_obj'
require_relative 'messages'
require_relative 'node'
require_relative 'node_buf'
require_relative 'syntax/syntax'
require_relative 'match/match_factory'
require_relative 'action/action_factory'
require_relative 'node_factory'
require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

module SheepAst
  # Ast hanling class
  #
  # @api private
  class AstManager < SheepObject
    extend T::Sig
    extend T::Helpers
    include Exception
    include Log
    abstract!

    sig { returns(NodeFactory) }
    attr_accessor :node_factory

    sig { returns(MatchFactory) }
    attr_accessor :match_factory

    sig { returns(String) }
    def inspect
      "custom inspect <#{self.class.name} object_id = #{object_id},"\
        " full_name = #{@full_name.inspect}>"
    end

    sig { void }
    def disable_action
      @disable_action = true
    end

    sig { void }
    def enable_action
      @disable_action = false
    end

    sig { void }
    def setup; end

    # @api public
    sig { params(name: String, data_store: DataStore, match_factory: MatchFactory).void }
    def initialize(name, data_store, match_factory)
      super()
      name_arr = name.split('.')
      if name_arr.length != 2
        application_error 'ast name should be format of "<domain>.<name>"'
      end
      @domain = name_arr[0]
      @name = name_arr[1]
      @full_name = name
      @node_factory = SheepAst::NodeFactory.new
      @data_store = data_store
      @match_factory = match_factory
      setup
    end

    # print abstrat syntax tree (AST)
    sig { params(logs: Symbol).void }
    def dump_tree(logs = :pfatal)
      @node_factory.dump_tree(logs)
    end

    # find the node from the dataession
    sig { params(data: AnalyzeData, node: T.nilable(Node)).returns(NodeInfo) }
    def find_next_node(data, node = nil)
      if node.nil?
        info = @node_factory.find_from_rootnode(data)
      else
        info = node.find_next_node(data)
      end

      return info
    end

    sig { params(matches: T::Array[MatchBase], action: ActionBase, name: String).void }
    def add(matches, action, name)
      action.my_ast_manager = self
      @node_factory.register_nodes(matches, action, name)
    end

    # Hook function when Ast is reached not found in its syntax tree.
    # This function can override by redefining from the object passed from config_ast.
    # It can be adjust sheep_ast behavior at when Ast cannot find any syntax in the tree.
    #
    # Default behavior is LazyAbort.
    # LazyAbort will raise abort if all the AstManager process is indicate NotFound
    #
    # @example
    #   core.config_ast do |ast, syn|
    #     ast.within {
    #       def not_found(data, node)
    #         # override contents
    #         # if you want, call original function
    #         not_found_orig(data, node)
    #       end
    #     }
    #   end
    #
    # @api public
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def not_found(data, node)
      not_found_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def not_found_orig(data, node)
      ldebug? and ldebug "'#{data.expr.inspect}' not found."
      if @aboort_immediate.nil?
        @aboort_immediate = ENV['SHEEP_ABORT_FAST']
      end
      if @abort_immediate
        return MatchAction::Abort
      else
        return MatchAction::LazyAbort
      end
    end

    # Same as not_found behavior, but this is used not found at the Ast tree is in progress.
    #
    # @api public
    #
    # @note please see not_found section for the example
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def not_found_in_progress(data, node)
      not_found_in_progress_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def not_found_in_progress_orig(data, node)
      ldebug? and ldebug "'#{data.expr.inspect}' not found in progress"
      if @aboort_immediate.nil?
        @aboort_immediate = ENV['SHEEP_ABORT_FAST']
      end
      if @abort_immediate
        return MatchAction::Abort
      else
        return MatchAction::LazyAbort
      end
    end

    # Hook function when condition match is in progress
    #
    # @api public
    #
    # @note please see not_found section for the example
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def condition_in_progress(data, node)
      condition_in_progress_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def condition_in_progress_orig(data, node)
      ldebug? and ldebug "matched '#{data.expr.inspect}' stay node"
      return MatchAction::StayNode
    end

    # Hook function when condition match is at the start
    #
    # @api public
    #
    # @note please see not_found section for the example
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def condition_start(data, node)
      condition_start_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def condition_start_orig(data, node)
      ldebug? and ldebug "matched '#{data.expr.inspect}' condition start. stay node"
      return MatchAction::StayNode
    end

    # Hook function during Ast is hit but not at the end
    #
    # @api public
    #
    # @note please see not_found section for the example
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def in_progress(data, node)
      in_progress_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def in_progress_orig(data, node)
      ldebug? and ldebug "matched '#{data.expr.inspect}' next data"
      return MatchAction::Next
    end

    # Hook function during Ast is hit but not at the end
    #
    # @api public
    #
    # @note please see not_found section for the example
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def condition_end_but_in_progress(data, node)
      condition_end_but_in_progress_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def condition_end_but_in_progress_orig(data, node)
      ldebug? and ldebug "matched '#{data.expr.inspect}' next data"
      return MatchAction::Next
    end

    # Hook function when Ast reached to its action (end of Ast process)
    #
    # @api public
    #
    # @note please see not_found section for the example
    #
    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def at_end(data, node)
      at_end_orig(data, node)
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def at_end_orig(data, node)
      if @disable_action
        ldebug? and ldebug 'SKIP ACTION ! : disable action is true, so return Finish without calling action', :gold
        return MatchAction::Finish
      end

      ldebug? and ldebug "Do ACTION ! : matched '#{data.expr.inspect}' at end"\
        ", invoking '#{node.my_action.inspect}' at end", :gold
      res = T.must(T.must(node).my_action).action(data, node)
      return res
    end
  end
end
