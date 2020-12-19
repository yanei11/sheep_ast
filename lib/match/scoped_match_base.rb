# typed: false
# frozen_string_literal: true

require_relative 'condition_match'
require 'sorbet-runtime'

module SheepAst
  # TBD
  class ScopedMatchBase < ConditionMatch
    extend T::Sig
    extend T::Helpers
    abstract!

    sig { returns(String) }
    attr_accessor :start_expr

    sig { returns(String) }
    attr_accessor :end_expr

    sig { returns(T::Array[T.any(String, Regexp)]) }
    attr_accessor :end_cond

    sig {
      params(
        start_expr: String,
        end_expr: String,
        sym: T.nilable(Symbol),
        options: T.nilable(
          T.any(
            T::Boolean, Symbol, String, Range,
            T::Array[T.any(String, Regexp)]
          )
        )
      ).returns(ScopedMatch)
    }
    def new(start_expr, end_expr, sym = nil, **options)
      ins = self.class.new(start_expr, sym, **options)
      ins.start_expr = start_expr
      ins.end_expr = end_expr
      ins.sem = 0
      ins.matched_expr = []
      return ins
    end

    sig { override.params(data: AnalyzeData).returns(T::Boolean) }
    def test_finish?(data)
      key = data.expr
      ret = false
      application_error('called when sem == 0') if @sem.zero?

      if match_end(@end_expr, key) && additional_end_cond(data)
        if sem_get == 1
          ret = true
          sem_set 0
        else
          sem_dec
        end
      elsif match_start(@start_expr, key)
        sem_inc
      end

      ldebug "test_finish ? key = #{key.inspect}, end_expr = #{@end_expr.inspect}, sem = #{@sem}, ret = #{ret}"

      return ret
    end

    def sem_set(sem)
      @sem = sem
    end

    def sem_get
      return @sem
    end

    def sem_inc
      @sem += 1
    end

    def sem_dec
      @sem -= 1
    end
  end
end
