# typed: false
# frozen_string_literal: true

require_relative 'match_base'
require 'sorbet-runtime'

module SheepAst
  # Regex Match instance
  #
  # @api public
  #
  class RegexMatch < MatchBase
    extend T::Sig

    # Create RegexMatch
    #
    # @example
    #   E(:r, '<regex exp>', [store symbol], [options])
    #
    # It matces if given expression match <regex exp>.
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
      ).returns(RegexMatch)
    }
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
  #
  # @api private
  #
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
