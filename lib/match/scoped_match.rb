# typed: false
# frozen_string_literal: true

require_relative 'scoped_match_base'
require 'sorbet-runtime'

module Sheep
  # TBD
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
