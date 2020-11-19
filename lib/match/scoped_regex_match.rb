# typed: strict
# frozen_string_literal: true

require_relative 'scoped_match'
require 'sorbet-runtime'

module Sheep
  # TBD
  class ScopedRegexMatch < ScopedMatch
    extend T::Sig
    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::RegexCondition
    end
  end
end
