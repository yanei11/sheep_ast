# typed: false
# frozen_string_literal: true

require_relative 'scoped_match_base'
require 'sorbet-runtime'

module Sheep
  # Scoped match instanc
  #
  # Syntax:
  # E(:sc, <start exp>, <end expr>, :<store sym>)
  #
  # It matces from if given expression == <start exp>
  # to if given expression == <end exp>.
  # In contrast to EnclosedMatch, ScopedMatch exit if <end exp> matches
  # same number of <start exp> matches.
  # i.e. if  given expression is `if { if { something } }` and <start exp>, <end exp> = { , }
  # then, scoped_match exit at 2nd }, but enclosed match exit first }
  #
  # Options:
  # regex_end : Use regexp match for the end_expr
  class ScopedMatch < ScopedMatchBase
    extend T::Sig

    sig { params(expr1: String, expr2: String).returns(T.nilable(T::Boolean)) }
    def match_end(expr1, expr2)
      options = options_get
      if options[:regex_end]
        reg_match(expr1, expr2)
      else
        expr1 == expr2
      end
    end

    sig { params(expr1: String, expr2: String).returns(T.nilable(T::Boolean)) }
    def match_start(expr1, expr2)
      if kind? == MatchKind::Condition
        expr1 == expr2
      else
        reg_match(expr1, expr2)
      end
    end

    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::Condition
    end
  end
end
