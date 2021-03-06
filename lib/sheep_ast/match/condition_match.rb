# typed: true
# frozen_string_literal:true

require_relative 'match_base'
require_relative '../log'
require 'sorbet-runtime'

module SheepAst
  # TBD
  class ConditionMatch < MatchBase
    extend T::Sig
    extend T::Helpers
    include Kernel
    include Log
    abstract!

    sig { returns(Integer) }
    attr_accessor :sem

    sig { returns(String) }
    attr_accessor :start_info

    sig { params(data: AnalyzeData).void }
    def start_condition(data)
      ldebug? and ldebug "start condition with expr #{data.expr.inspect}"
      @sem = 1
      @start_info = "#{data.nil?}:#{data.to_enum}: start key:#{data.expr.inspect}"
      @start_line = data.file_info&.line
      @start_index = data.file_info&.index
    end

    sig { abstract.params(data: AnalyzeData).returns(T::Boolean) }
    def test_finish?(data); end

    sig { params(data: AnalyzeData).void }
    def end_condition(data)
      ldebug? and ldebug "ConditionMatch ended by key:#{data.expr.inspect}."\
        "End at #{T.must(data.file_info).file}:#{T.must(data.file_info).line}."\
        "It was start from #{@start_info}."
      @start_info = nil
      @sem = 0
      options_ = T.cast(@options, T::Hash[Symbol, T::Boolean])
      data.request_next_data = RequestNextData::Again if T.must(options_)[:end_reinput]
      @end_line = data.file_info&.line
      @end_index = data.file_info&.index
    end

    def start_info_set(line, index); end

    def end_info_set(line, index); end

    sig { override.void }
    def init
      @matched_expr = []
    end
  end

  # Condition Match Util
  module ConditionMatchUtil
    extend T::Sig
    include MatchUtil
    include Log
    include Kernel

    sig { void }
    def initialize
      @condition_flag = false
      @pre_condition_flag = false
      @active_match = nil
      @condition_matches = {}
      @global_matches[MatchKind::Condition.rank] = @condition_matches
      @methods_array << prio(200, method(:check_condition_match))
      @regex_condition_matches = {}
      @global_matches[MatchKind::RegexCondition.rank] = @regex_condition_matches
      @methods_array << prio(210, method(:check_regex_condition_match))
      @methods_array << prio(10, method(:try_condition_scope))
      super()
    end

    sig { params(data: AnalyzeData).returns(T.nilable(MatchBase)) }
    def try_condition_scope(data) # rubocop: disable all
      if @condition_flag
        if !@active_match.test_finish?(data)
          ldebug? and ldebug "In condition match. expr = #{data.expr}. condition flag = true. continue"
        else
          ldebug? and ldebug "matched. expr = #{data.expr}. condition flag = false"
          @active_match.end_condition(data)
          down_condition_flag(@active_match)
        end
        @active_match.matched(data)
      else
        @active_match = nil
      end
      return @active_match
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(ConditionMatch))
    }
    def check_condition_match(data)
      match = MatchBase.check_exact_condition(@condition_matches, data.expr, data)
      if !match.nil?
        ldebug? and ldebug "matched. expr = #{data.expr}. condition flag = true"
        @active_match = match
        @active_match.init
        @active_match.start_condition(data)
        @active_match.matched(data)
        up_condition_flag(match)
        return match
      end
      return nil
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(ConditionMatch))
    }
    def check_regex_condition_match(data)
      @regex_condition_matches.each do |_, match|
        test = MatchBase.check_regex_condition(match, data)
        next if test.nil?

        @active_match = match
        @active_match.init
        @active_match.start_condition(data)
        @active_match.matched(data)
        up_condition_flag(match)
        return match
      end
      return nil
    end

    sig { returns(T::Boolean) }
    def condition_change?
      ldebug? and ldebug "condition_flag = #{@condition_flag}, pre_condition_flag = #{@pre_condition_flag}"
      if @condition_flag == @pre_condition_flag
        return false
      else
        ldebug? and ldebug 'condition change'
        @pre_condition_flag = @condition_flag
        return true
      end
    end

    sig { params(match: MatchBase).void }
    def up_condition_flag(match)
      @condition_flag = true
      incl = @active_match.ast_include
      excl = @active_match.ast_exclude
      T.unsafe(self).condition_up_action(incl, excl)
    end

    sig { params(match: MatchBase).void }
    def down_condition_flag(match)
      @condition_flag = false
      T.unsafe(self).condition_down_action
    end
  end
end
