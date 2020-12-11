# typed: false
# frozen_string_literal: true

require_relative 'exception'
require_relative 'log'
require_relative 'sheep_obj'
require_relative 'messages'
require_relative 'node'
require_relative 'node_buf'
require_relative 'syntax'
require_relative 'match/match_factory'
require_relative 'action/action_factory'
require_relative 'node_factory'
require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

module SheepAst
  # interface class for the user
  # API class. User should use this class as Interface
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
      "custom inspect <#{self.class.name} object_id = #{object_id}, full_name = #{@full_name.inspect}>"
    end

    sig { void }
    def setup; end

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
    sig { params(data: AnalyzeData, node: Node).returns(NodeInfo) }
    def find_next_node(data, node = nil)
      if node.nil?
        info = @node_factory.find_from_root_node(data)
      else
        info = node.find_next_node(data)
      end

      return info
    end

    sig { params(matches: T::Array[MatchBase], action: ActionBase, name: String).void }
    def add(matches, action, name)
      @node_factory.register_nodes(matches, action, name)
    end

    sig { params(data: AnalyzeData, _node: Node).returns(MatchAction) }
    def not_found(data, _node)
      ldebug "'#{data.expr.inspect}' not found."
      if @aboort_immediate.nil?
        @aboort_immediate = ENV['SHEEP_ABORT_FAST']
      end
      if @abort_immediate
        return MatchAction::Abort
      else
        return MatchAction::LazyAbort
      end
    end

    sig { params(data: AnalyzeData, _node: Node).returns(MatchAction) }
    def not_found_in_progress(data, _node)
      ldebug "'#{data.expr.inspect}' not found in progress"
      if @aboort_immediate.nil?
        @aboort_immediate = ENV['SHEEP_ABORT_FAST']
      end
      if @abort_immediate
        return MatchAction::Abort
      else
        return MatchAction::LazyAbort
      end
    end

    sig { params(data: AnalyzeData, _node: Node).returns(MatchAction) }
    def condition_in_progress(data, _node)
      ldebug "matched '#{data.expr.inspect}' stay node"
      return MatchAction::StayNode
    end

    sig { params(data: AnalyzeData, _node: Node).returns(MatchAction) }
    def condition_start(data, _node)
      ldebug "matched '#{data.expr.inspect}' condition start. stay node"
      return MatchAction::StayNode
    end

    sig { params(data: AnalyzeData, _node: Node).returns(MatchAction) }
    def in_progress(data, _node)
      ldebug "matched '#{data.expr.inspect}' next data"
      return MatchAction::Next
    end

    sig { params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def at_end(data, node)
      ldebug "matched '#{data.expr.inspect}' at end"
      ldebug "invoking '#{node.my_action.inspect}' at end"
      res = node.my_action.action(data, node)
      return res
    end
  end
end
