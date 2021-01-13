# typed: strict
# frozen_string_literal: true

require_relative 'match_base'
require_relative '../data_handle_util'
require 'sorbet-runtime'

module SheepAst
  # TBD
  class IndexCondition
    extend T::Sig
    include Log
    include Exception
    include DataHandle

    sig {
      params(
        exprs: T.any(String, Regexp, T::Array[T.any(String, Regexp)]),
        options: T.untyped
      ).void
    }
    def initialize(*exprs, **options)
      super()
      T.unsafe(self).data_handle_init(exprs, **options)
    end
  end
end
