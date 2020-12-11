# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'sheep_obj'
require_relative 'match/match_factory'
require_relative 'action/action_factory'
require_relative 'action/action_base'
require_relative 'syntax_alias'
require 'sorbet-runtime'

module SheepAst
  # utility to perform deep copy for Hash or Array
  class Syntax < SheepObject
    extend T::Sig
    include Exception
    include Log
    include SyntaxAlias

    sig { returns(ActionBase) }
    def action
      return @action
    end

    sig { returns(T::Array[ActionBase]) }
    def actions
      return @action
    end

    sig { params(ast: AstManager, mfctry: MatchFactory, afctry: ActionFactory).void }
    def initialize(ast, mfctry, afctry)
      super()
      @ast = ast
      @mf = mfctry
      @af = afctry
      @action = nil
    end

    def depth(array)
      return 0 unless array.is_a?(Array)

      return 1 + depth(array[0])
    end

    def register_syntax(name, action = nil, &blk)
      arrs = blk.call
      if depth(arrs) == 1
        arrs = [arrs]
      end

      if action.nil?
        arrs.each_with_index do |arr, i|
          match = T.must(arr[0..-2])
          action_ = T.must(arr[-1..-1])
          @action = action_
          @ast.add(match, T.cast(action_[0], ActionBase), "group(#{name})-#{i + 1}")
        end
      else
        @action = action
        arrs.each_with_index do |arr, i|
          match = T.must(arr[0..-1]) #rubocop:disable all
          @ast.add(match, T.cast(action, ActionBase), "group(#{name})-#{i + 1}")
        end
      end
    end
  end
end
