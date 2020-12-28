# typed:true
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
      ldebug "start condition with expr #{data.expr.inspect}"
      @sem = 1
      @start_info = "#{data.nil?}:#{data.to_enum}: start key:#{data.expr.inspect}"
      @start_line = data.file_info&.line
      @start_index = data.file_info&.index
      @start_line = data.file_info&.line
      @start_index = data.file_info&.index
    end

    sig { abstract.params(data: AnalyzeData).returns(T::Boolean) }
    def test_finish?(data); end

    sig { params(data: AnalyzeData).void }
    def end_condition(data)
      ldebug "ConditionMatch ended by key:#{data.expr.inspect}."\
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
          ldebug "In condition match. expr = #{data.expr}. condition flag = true. continue"
        else
          ldebug "matched. expr = #{data.expr}. condition flag = false"
          @condition_flag = false
          @active_match.end_condition(data)
          # @active_match.matched_end(data)
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
      match = @condition_matches[data.expr]
      if !match.nil?
        ldebug "matched. expr = #{data.expr}. condition flag = true"
        @condition_flag = true
        @active_match = match
        @active_match.init
        @active_match.start_condition(data)
        @active_match.matched(data)
        return match
      end
      return nil
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(ConditionMatch))
    }
    def check_regex_condition_match(data)
      @regex_condition_matches.each do |_, match|
        test = match.match(data)
        next if test.nil?

        @condition_flag = true
        @active_match = match
        @active_match.init
        @active_match.start_condition(data)
        @active_match.matched(data)
        return match
      end
      return nil
    end

    sig { returns(T::Boolean) }
    def condition_change?
      if @condition_flag == @pre_condition_flag
        return false
      else
        @pre_condition_flag = @condition_flag
        return true
      end
    end
  end
end
