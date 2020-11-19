# typed: false
# frozen_string_literal:true

require_relative 'match_base'
require 'sorbet-runtime'

module Sheep
  # TBD
  class ExactGroupMatch < MatchBase
    extend T::Sig

    sig { returns(T::Array[String]) }
    attr_accessor :keys

    sig {
      params(keys: T::Array[String],
             sym: T.nilable(Symbol), options: T.nilable(T::Boolean)).returns(ExactGroupMatch)
    }
    def new(keys, sym = nil, **options)
      ins = ExactGroupMatch.new(keys.inspect.to_s, sym, **options)
      ins.keys = keys
      return ins
    end

    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::ExactGroup
    end

    sig { override.void }
    def init
      @expr = ''
    end

    sig { params(data: AnalyzeData).returns(T::Boolean) }
    def lookup(data)
      key = data.expr
      ldebug "lookup for #{T.must(key)}"
      @keys.each do |item|
        if key == item
          ldebug 'Found'
          return true
        end
      end
      ldebug "Not Found => group keys: #{keys.inspect}"
      return false
    end
  end

  # Match to handle exact group match
  module ExactGroupMatchUtil
    extend T::Sig
    include MatchUtil
    include Kernel

    sig { void }
    def initialize
      @exact_group_matches = {}
      @global_matches[MatchKind::ExactGroup.rank] = @exact_group_matches
      @methods_array << prio(150, method(:check_exact_group_match))
      super()
    end

    sig {
      params(data: AnalyzeData).returns(T.nilable(MatchBase))
    }
    def check_exact_group_match(data)
      @exact_group_matches.each do |_, a_chain|
        test = a_chain.lookup(data)
        next if test.nil?

        a_chain.init
        a_chain.matched(data)
        # a_chain.matched_end(data)
        return a_chain
      end
      return nil
    end
  end
end
