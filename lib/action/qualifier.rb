# typed:true
# frozen_string_literal:true

require_relative 'action_base'
require_relative '../log'
require_relative '../exception'
require_relative '../data_handle_util'
require 'sorbet-runtime'

module SheepAst
  # This class is for the action to recprd the result
  class Qualifier
    extend T::Sig
    include Log
    include Exception
    include DataHandle

    sig {
      params(
        exprs: T.any(String, Regexp, T::Array[T.any(String, Regexp)]),
        not_: T::Boolean,
        options: T.nilable(T.any(T::Boolean, Symbol, String, Range, Integer))
      ).void
    }
    def initialize(exprs, not_ = true, **options) # rubocop:disable all
      super()
      data_handle_init(exprs, **options)
      @not = not_
    end

    sig { params(data: AnalyzeData).returns(T::Boolean) }
    def qualify(data)
      ret = validate(data)
      if @not
        return !ret
      else
        return ret
      end
    end
  end
end
