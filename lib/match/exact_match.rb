# typed: false
# frozen_string_literal: true

require_relative 'match_base'
require 'sorbet-runtime'

module SheepAst
  # Exact match instance
  #
  # Syntax:
  # E(:e, '<expr>', :<store symbol>)
  #
  # It match if given expression == <expr>.
  # It store matched data in :<store symbol> in data
  class ExactMatch < MatchBase
    extend T::Sig

    sig {
      params(
        key: String,
        sym: T.nilable(Symbol),
        options: T.nilable(T.any(T::Boolean, Symbol, String))
      ).returns(ExactMatch)
    }
    def new(key, sym = nil, **options)
      em = ExactMatch.new(key, sym, **options)
      em.init
      return em
    end

    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::Exact
    end

    sig { override.void }
    def init
      @expr = ''
    end
  end

  # to include exact match util
  module ExactMatchUtil
    extend T::Sig
    include MatchUtil
    include Kernel

    sig { void }
    def initialize
      super()
      @exact_matches = {}
      @global_matches[MatchKind::Exact.rank] = @exact_matches
      @methods_array << prio(100, method(:check_exact_match))
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(MatchBase))
    }
    def check_exact_match(data)
      key = data.expr

      match = @exact_matches[key]
      return nil if match.nil?

      match.init
      match.matched(data)
      # match.matched_end(data)
      return match
    end
  end
end
