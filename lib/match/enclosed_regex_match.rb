# typed:true
# frozen_string_literal:true

require_relative 'scoped_regex_match'
require 'sorbet-runtime'

module Sheep
  # Enclosed Regex match instance
  #
  # Syntax:
  # E(:scr, <start exp>, <end expr>, :<store sym>)
  #
  # It matces from if given expression matches regex expression <start exp>
  # to if given expression == <end exp>.
  # In contrast to ScopedRegexMatch, EnclosedRegexMatch exit immediately if
  # the <end exp> matched.
  #
  # Options:
  # regex_end : Use regexp match for the end_expr
  class EnclosedRegexMatch < ScopedRegexMatch
    extend T::Sig

    def sem_inc
      @sem = 1
    end

    def sem_dec
      @sem = 0
    end
  end
end
