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

    sig {
      params(
        name: String,
        action_: ActionBase,
        blk: T.proc.returns(T::Array[T::Array[T.any(String, Symbol)]])
      ).void
    }
    def register(name, action_, &blk)
      arr = blk.call
      match = arr.map { |arg| T.unsafe(@mf).gen(*arg) }
      @action = action_
      @ast.add(match, action_, name)
    end

    sig {
      params(
        name: String,
        blk: T.proc.returns(T::Array[T::Array[T.any(String, Symbol)]])
      ).void
    }
    def register_array(name, &blk)
      arr = blk.call
      match = T.must(arr[0..-2]).map { |arg| T.unsafe(@mf).gen(*arg) }
      action_ = T.unsafe(@af).gen(T.must(arr[-1])[0])
      @action = action_
      @ast.add(match, action_, name)
    end

    sig {
      params(
        name_base: String,
        action_: T.any(ActionBase, T::Array[ActionBase]),
        blk: T.proc.returns(T::Array[T::Array[T::Array[T.any(String, Symbol)]]])
      ).void
    }
    def register_multi(name_base, action_, &blk)
      arrs = blk.call
      if action_.respond_to?(:each)
        t_arr = T.cast(action_, T::Array[ActionBase])
        is_arr = true
        if arrs.length != t_arr.length
          application_error 'action_ arr mismatch dimension'
        end
      end

      @action = action_
      arrs.each_with_index do |arr, i|
        match = arr.map { |arg| T.unsafe(@mf).gen(*arg) }
        if is_arr
          @ast.add(match,
                   T.must(T.cast(action_, T::Array[ActionBase])[i]),
                   "group(#{name_base})-#{i + 1}")
        else
          @ast.add(match,
                   T.cast(action_, ActionBase),
                   "group(#{name_base})-#{i + 1}")
        end
      end
    end

    sig {
      params(
        name_base: String,
        blk: T.proc.returns(T::Array[T::Array[T::Array[T.any(String, Symbol)]]])
      ).void
    }
    def register_array_multi(name_base, &blk)
      @action = []
      arrs = blk.call
      arrs.each_with_index do |arr, i|
        match = T.must(arr[0..-2]).map { |arg| T.unsafe(@mf).gen(*arg) }
        action_ = T.must(arr[-1..-1]).map { |arg| T.unsafe(@af).gen(*arg) }
        @action << action_
        @ast.add(match, T.cast(action_[0], ActionBase), "group(#{name_base})-#{i + 1}")
      end
    end

    def register_syntax(name, action = nil, &blk)
      arrs = blk.call
      if action.nil?
        arrs.each_with_index do |arr, i|
          match = T.must(arr[0..-2]).map { |arg| T.unsafe(@mf).gen(*arg) }
          action_ = T.must(arr[-1..-1])
          @action = action_
          @ast.add(match, T.cast(action_[0], ActionBase), "group(#{name})-#{i + 1}")
        end
      else
        @action = action
        arrs.each_with_index do |arr, i|
          match = T.must(arr[0..-1]).map { |arg| T.unsafe(@mf).gen(*arg) } #rubocop:disable all
          @ast.add(match, T.cast(action, ActionBase), "group(#{name})-#{i + 1}")
        end
      end
    end
  end
end
