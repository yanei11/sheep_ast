# typed: false
# Copyright 2019 Ryhei Yaginiwa. All right reserved.
# frozen_string_literal: true

require_relative 'log'
require_relative 'exception'
require_relative 'match/match_base'
require_relative 'action/action_base'
require 'rainbow/refinement'

using Rainbow

module Sheep
  # TBD give brief explanation
  class NodeBuf
    extend T::Sig
    include Exception
    include Log

    sig { returns(MatchBase) }
    attr_accessor :match

    sig { returns(ActionBase) }
    attr_accessor :action

    sig {
      params(matches: T::Hash[MatchBase, String],
             match: T.nilable(MatchBase), chain_id: Integer, group: T.nilable(String)).void
    }
    def initialize(matches, match, chain_id, group)
      @@buffer = +''
      @@dump_width = 20
      @matches = matches
      @match = match
      @chain_id = chain_id
      @my_group = group
      super()
    end

    sig { params(action: ActionBase).void }
    def reg_action(action)
      application_error 'Action duplicated' unless @action.nil?
      @action = action
    end

    sig { void }
    def save_tree_from_here
      if !@match.nil?
        expr = "(#{@match.kind_name})#{@match.key.inspect}"
      end

      if !expr.nil?
        @@buffer << expr.ljust(@@dump_width).slice(0, @@dump_width)
        @@buffer << ' -> '
      end

      @matches.each do |_, a_node|
        a_node.node_buffer.save_tree_from_here
        @@buffer << "\n"
        @@buffer << ' '.dup * (@@dump_width + 4) * @chain_id
      end

      unless @action.nil?
        @@buffer << @action.description
        @@buffer << " [name: #{@my_group}]"
      end
    end

    sig { params(logs: Symbol).void }
    def dump_buffer(logs)
      logf = method(logs)
      @@buffer.each_line do |line|
        unless /^\s*$/ =~ line
          logf.call line.chomp.cyan
        end
      end
    end

    class << self
      extend T::Sig

      sig { void }
      def buffer_init
        @@buffer = +''
      end
    end
  end
end
