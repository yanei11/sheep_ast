# typed: false
# frozen_string_literal: true

require_relative 'scoped_match_base'
require 'sorbet-runtime'

module SheepAst
  # Scoped match instanc
  #
  # @see #new
  #
  class ScopedMatch < ScopedMatchBase
    extend T::Sig

    # @api private
    sig { params(expr1: String, expr2: String).returns(T.nilable(T::Boolean)) }
    def match_end(expr1, expr2)
      if @options[:regex_end]
        reg_match(expr1, expr2)
      else
        expr1 == expr2
      end
    end

    # @api private
    sig { params(expr1: String, expr2: String).returns(T.nilable(T::Boolean)) }
    def match_start(expr1, expr2)
      if kind? == MatchKind::Condition
        expr1 == expr2
      else
        reg_match(expr1, expr2)
      end
    end

    # @api private
    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::Condition
    end
  end
end
