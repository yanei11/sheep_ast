# typed: true
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

    # Creates Scoped/ScopedRegex/Enclosed/EnclosedRegex Match
    #
    # @example
    #   E(:sc, <start exp>, <end expr>, [store sym], [options])
    #   E(:enc, <start exp>, <end expr>, [store sym], [options])
    #   E(:scr, <start exp>, <end expr>, [store sym], [options])
    #   E(:encr, <start exp>, <end expr>, [store sym], [options])
    #
    # It matces from if given expression == <start exp>
    # to if given expression == <end exp>.
    # In contrast to EnclosedMatch, ScopedMatch exit if <end exp> matches
    # same number of <start exp> matches.
    #
    # i.e. if  given expression is `if { if { something } }` and if <start exp>, = {  and <end exp> =  }
    # then, scoped_match exit at 2nd }, but enclosed match exit first }
    # It store matched expression to [store symbol] in the data.
    # If store symbol is not specified, framework gives default symbol.
    #
    # @option options [Integer] :repeat Retruns same instance for specified count
    # @option options [Boolean] :at_head Match when the expression is head of the sentence
    # @option options [IndexCondition] :index_cond Additional condition to match arbeitary index of sentence
    # @option options [IndexCondition] :end_cond Additional condition to match arbeitary index of sentence at the end
    # @see IndexCondition
    #
    # @api public
    #
    sig {
      params(
        start_expr: String,
        end_expr: String,
        sym: T.nilable(Symbol),
        options: T.untyped
      ).returns(ScopedMatch)
    }
    def new(start_expr, end_expr, sym = nil, **options)
      ins = T.unsafe(self).class.new(start_expr, sym, **options)
      ins.start_expr = start_expr
      ins.end_expr = end_expr
      ins.sem = 0
      ins.matched_expr = []
      return ins
    end

    def match_end(expr, key, data); end

    def match_start(expr, key, data); end

    sig { override.params(data: AnalyzeData).returns(T::Boolean) }
    def test_finish?(data)
      key = data.expr
      ret = false
      application_error('called when sem == 0') if @sem.zero?

      if match_end(@end_expr, key, data) && additional_end_cond(data)
        if sem_get == 1
          ret = true
          sem_set 0
        else
          sem_dec
        end
      elsif match_start(@start_expr, key, data)
        sem_inc
      end

      ldebug? and ldebug "test_finish ? key = #{key.inspect},"\
        " end_expr = #{@end_expr.inspect}, sem = #{@sem}, ret = #{ret}"

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
