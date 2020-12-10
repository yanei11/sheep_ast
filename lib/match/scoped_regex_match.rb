# typed: strict
# frozen_string_literal: true

require_relative 'scoped_match'
require 'sorbet-runtime'

module Sheep
  # Scoped Regex match instance
  #
  # Syntax:
  # E(:scr, <start exp>, <end expr>, :<store sym>)
  #
  # It matces from if given expression matches regex expression <start exp>
  # to if given expression == <end exp>.
  # In contrast to EnclosedRgexMatch, ScopedRegexMatch exit if <end exp> matches
  # same number of <start exp> matches.
  # i.e. if  given expression is `if { if { something } }` and <start exp>, <end exp> = { , }
  # then, scoped_match exit at 2nd }, but enclosed match exit first }
  #
  # Options:
  # regex_end : Use regexp match for the end_expr
  class ScopedRegexMatch < ScopedMatch
    extend T::Sig
    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::RegexCondition
    end
  end
end
