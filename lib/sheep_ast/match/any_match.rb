# typed: false
# frozen_string_literal: true

require_relative 'match_base'
require 'sorbet-runtime'

module SheepAst
  # Exact match instance
  class AnyMatch < MatchBase
    extend T::Sig

    # To create exact match
    #
    # @example
    #   E(:e, '<expr>', [store symbol], [options])
    #
    # It match if given expression == <expr>.
    # It store matched expression to [store symbol] in the data.
    # If store symbol is not specified, framework gives default symbol.
    #
    # @option options [Range] :extract To modify matched string by range
    # @option options [Boolean] :at_head Match when the expression is head of the sentence
    # @option options [IndexCondition] :index_cond Additional condition to match arbeitary index of sentene
    # @see IndexCondition
    #
    # @api public
    #
    sig {
      params(
        key: String,
        sym: T.nilable(Symbol),
        options: T.untyped
      ).returns(AnyMatch)
    }
    def new(key, sym = nil, **options)
      am = AnyMatch.new(key, sym, **options)
      am.init
      return am
    end

    # @api private
    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::Any
    end

    # @api private
    sig { override.void }
    def init
      @expr = ''
    end
  end

  # to include exact match util
  # @api private
  module AnyMatchUtil
    extend T::Sig
    include MatchUtil
    include Kernel

    sig { void }
    def initialize
      super()
      @any_matches = {}
      @global_matches[MatchKind::Any.rank] = @any_matches
      @methods_array << prio(5, method(:check_any_match))
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(MatchBase))
    }
    def check_any_match(data)
      match = @any_matches['any']
      return nil if match.nil?

      match.init
      match.matched(data)
      # match.matched_end(data)
      return match
    end
  end
end
