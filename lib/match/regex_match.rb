# typed: false
# frozen_string_literal: true

require_relative 'match_base'
require 'sorbet-runtime'

module Sheep
  # Regex Match instance
  #
  # Syntax:
  # E(:re, '<regex exp>', :<store symbol>)
  #
  # It matces if given expression match <regex exp>.
  # It store matced expression in the <store symbol>
  class RegexMatch < MatchBase
    extend T::Sig

    sig { params(key: String, sym: T.nilable(Symbol), options: T.nilable(T::Boolean)).returns(RegexMatch) }
    def new(key, sym = nil, **options)
      return RegexMatch.new(key, sym, **options)
    end

    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::Regex
    end

    sig { override.void }
    def init
      @expr = ''
    end
  end

  # Regex match utility
  module RegexMatchUtil
    extend T::Sig
    include MatchUtil
    include Kernel

    sig { void }
    def initialize
      @regex_matches = {}
      @global_matches[MatchKind::Regex.rank] = @regex_matches
      @methods_array << prio(300, method(:check_regex_match))
      super()
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(MatchBase))
    }
    def check_regex_match(data)
      @regex_matches.each do |_, a_chain|
        test = a_chain.match(data)
        next if test.nil?

        a_chain.matched(data)
        # a_chain.matched_end(data)
        return a_chain
      end
      return nil
    end
  end
end
