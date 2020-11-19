# typed:true
# frozen_string_literal:true

require_relative 'scoped_regex_match'
require 'sorbet-runtime'

module Sheep
  # TBD
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
