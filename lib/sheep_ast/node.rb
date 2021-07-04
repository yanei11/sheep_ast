# typed:true
# frozen_string_literal: true

require 'rainbow/refinement'
require_relative 'exception'
require_relative 'log'
require_relative 'node_buf'
require_relative 'match/match_factory'

using Rainbow

module SheepAst
  # Sheep Ast node representation
  #
  # @api private
  #
  class Node < SheepObject
    include Log
    include Exception
    include ExactMatchUtil
    include ExactGroupMatchUtil
    include RegexMatchUtil
    include ConditionMatchUtil
    include AnyMatchUtil
    extend T::Sig

    sig { returns(T::Hash[Integer, T::Hash[String, MatchBase]]) }
    attr_accessor :global_matches

    sig { returns(T::Array[Method]) }
    attr_accessor :methods_array

    sig { returns(SheepAst::NodeBuf) }
    attr_reader :node_buffer

    sig { returns(T.nilable(ActionBase)) }
    attr_reader :my_action

    sig { returns(T.nilable(Integer)) }
    attr_reader :my_chain_id

    sig { returns(NodeFactory) }
    attr_accessor :my_node_factory

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :my_tag

    sig { returns(T.nilable(Node)) }
    attr_accessor :parent_node

    sig {
      params(chain_num: Integer, match: T.nilable(MatchBase),
             group: T.nilable(String)).void
    }
    def initialize(chain_num, match = nil, group = nil)
      @my_group = group
      @my_match = match
      @my_chain_id = chain_num
      T.must(@my_match).my_chain_num = chain_num unless match.nil?
      @matches_to_node = {}
      @matches_to_match = {}
      @node_buffer = NodeBuf.new(@matches_to_node, @my_match, @my_chain_id, @my_group)
      @methods_array = []
      @global_matches = {}
      @methods_array = []
      @ordered_methods_array = []
      super()
    end

    sig { returns(String) }
    def inspect
      "custom inspect: <#{self.class.name} object_id = #{object_id}, my_group = #{@my_group}, "\
        "my_match = #{@my_match.inspect}, matches = #{@maches_to_node.inspect}, "\
        "my_chain_id = #{@my_chain_id}, my_tag = #{my_tag}>"
    end

    # create node from the match kind and the key
    sig {
      params(chain_num: Integer,
             match: MatchBase, group: String).returns(Node)
    }
    def create(chain_num, match, group)
      a_node = Node.new(chain_num, match, group)
      a_node.my_node_factory = @my_node_factory
      @my_node_factory.create_id(a_node)
      register_node(a_node, match)
      return a_node
    end

    # register action
    sig {
      params(
        action: ActionBase, qualifier: T.nilable(Qualifier)
      ).void
    }
    def reg_action(action, qualifier = nil)
      if !@my_action.nil?
        application_error 'action already registered. Maybe duplicated ast entry'
      end
      @my_action = action
      @my_action.register_qualifier(qualifier) unless qualifier.nil?
      @node_buffer.reg_action(action)
    end

    # find node key keyession
    sig { params(key: String).returns(T.nilable(Node)) }
    def find(key)
      return @matches_to_node[key]
    end

    # find next node from maps the node has
    sig { params(data: AnalyzeData).returns(NodeInfo) }
    def find_next_node(data) # rubocop: disable all
      ldebug? and ldebug "#{inspect} start processing..."

      if @reordered.nil?
        reordered
        @reordered = true
      end

      @ordered_methods_array.each do |m| #rubocop: disable all
        match = m.call(data)
        ldebug? and ldebug "Got match #{match.inspect} at #{m.name}" unless match.nil?

        # match = nil unless match&.additional_cond(data)
        # if !match.nil? && !match.validate(data)
        #   ldebug? and ldebug 'Additional condition cannot be fullfiled. set nil'
        #   match = nil
        # end

        node_info_ = match&.node_info
        next if node_info_.nil?

        node_info = NodeInfo.new
        node_info.copy(node_info_)
        node_info.status = MatchStatus::NotFound

        node = @my_node_factory.from_id(node_info.node_id)

        if @condition_flag
          # Strategy 0
          # The condition match is not done.
          # This is clearly not End of AST lookup
          if condition_change?
            ldebug? and ldebug 'node judged to MatchStatus::ConditionMatchingStart'
            node_info.status = MatchStatus::ConditionMatchingStart
          else
            ldebug? and ldebug 'node judged to MatchStatus::ConditionMatchingProgress'
            node_info.status = MatchStatus::ConditionMatchingProgress
          end
        elsif node.my_action.nil?
          # Strategy 1.
          # The action is nil.
          # This is the case to continue scanning
          node_info.status = MatchStatus::MatchingProgress
          ldebug? and ldebug 'node judged to MatchStatus::MatchingProgress, route1'
        elsif !node.my_action.need_qualify?
          # Strategy 2
          # The action is not nil and condition match is not scope
          # This is the case of End AST lookup since there are no another nodes
          # to look up but only action
          node_info.status = MatchStatus::AtEnd
          ldebug? and ldebug 'node judged to  MatchStatus::AtEnd, route1'
        elsif node.my_action.really_end?(data)
          # Strategy 3
          # The action is not nil and condition match is not scope
          # This is the case of End AST by user specified really_end? function
          node_info.status = MatchStatus::AtEnd
          ldebug? and ldebug 'node judged to  MatchStatus::AtEnd, route2'
        else
          # Strategy 4
          # So, this is the case of not really_end.
          # This is not End of AST lookup
          node_info.status = MatchStatus::MatchingProgress
          ldebug? and ldebug 'node judged to MatchStatus::MatchingProgress, route2'
        end

        ldebug? and ldebug "node_info.status = #{node_info.status}"
        ldebug? and ldebug "condition flag = #{@condition_flag.inspect}"
        if node_info.status == MatchStatus::AtEnd && condition_change?
          ldebug? and ldebug 'node judged to MatchStatus::ConditionMatchingAtEnd'
          node_info.status = MatchStatus::ConditionMatchingAtEnd
        end

        if node_info.status == MatchStatus::MatchingProgress && condition_change?
          ldebug? and ldebug 'node judged to MatchStatus::ConditionEndButMatchingProgress'
          node_info.status = MatchStatus::ConditionEndButMatchingProgress
        end

        return node_info
      end

      # Strategy5
      # The given keyword does not match any registered nodes.
      # This is not found status

      ldebug? and ldebug "No matching match. NotFound. my_id = #{@my_id}, object_id = #{object_id}"
      return NodeInfo.new(status: MatchStatus::NotFound)
    end

    sig { void }
    def reordered
      tmp = @methods_array.sort { |a, b| a[0] <=> b[0] }
      @ordered_methods_array = tmp.transpose[1]
    end

    sig { returns(T::Array[NextCommand]) }
    def next_command
      res = []
      @matches_to_match.each do |_k, v|
        next_command = NextCommand.new
        next_command.command = v.command
        next_command.description = v.description
        res << next_command
      end
      return res
    end

    def condition_up_action(incl, excl)
      @my_node_factory.my_manager.stage_manager.condition_incl = incl
      @my_node_factory.my_manager.stage_manager.condition_excl = excl
    end

    def condition_down_action
      @my_node_factory.my_manager.stage_manager.condition_incl = nil
      @my_node_factory.my_manager.stage_manager.condition_excl = nil
    end

    private

    sig { params(node: Node, match: MatchBase).void }
    def register_node(node, match) # rubocop: disable all
      match.node_id = node.my_id.dup
      match_container = global_matches[match.kind?.rank]
      node.my_tag = match.my_tag
      node.parent_node = self
      @my_node_factory.register_tag(node.my_tag, node) if node.my_tag
      application_error 'unknown match' if match_container.nil?

      if match_container.key? match.key
        lfatal "Same key is detected for => #{match.inspect}"
        application_error
      end

      if @my_match.nil?
        ldebug? and ldebug "register_node: my node = root, got '#{match.key}',my id = #{my_id}"\
          " my obect_id = #{object_id}, assigned id = #{node.my_id}, assigned object_id = #{node.object_id}"
      else
        ldebug? and ldebug "register_node: my node = #{@my_match.key}, got '#{match.key}', "\
          " my object_id = #{object_id}, assigned id = #{node.my_id}, assigned object_id = #{node.object_id}"
      end

      match_container[match.key] = match
      @matches_to_node[match.key] = node
      @matches_to_match[match.key] = match
    end
  end
end
