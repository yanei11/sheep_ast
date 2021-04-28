# typed:true
# frozen_string_literal:true

require_relative '../log'
require_relative '../sheep_obj'
require_relative '../match/match_factory'
require_relative '../action/action_factory'
require_relative '../action/action_base'
require_relative 'syntax_alias'
require 'sorbet-runtime'

module SheepAst
  # Wrap Ast defining process from User input, and provides
  #  better syntax to user
  #
  #  @api public
  #
  class Syntax < SheepObject
    extend T::Sig
    include Exception
    include Log
    include SyntaxAlias

    sig { params(ast: AstManager, mfctry: MatchFactory, afctry: ActionFactory).void }
    def initialize(ast, mfctry, afctry)
      super()
      @ast = ast
      @mf = mfctry
      @af = afctry
      @action = nil
    end

    # Gives user to add Ast definition to handle analysis
    #
    # @example Usage example
    #   core.config_ast do |ast, syn|
    #     syn.within {
    #       register_syntax('ast.name') {
    #         SS(
    #           S() << E(..) << E(..) << A(..),
    #           S() << ...,,
    #           S() << ...
    #           ...
    #         )
    #       }
    #     }
    #   end
    #
    # @example name can be omitted. name is set as ast name in this case.
    #   core.config_ast do |ast, syn|
    #     syn.within {
    #       register_syntax {
    #         SS(
    #           S() << E(..) << E(..) << A(..),
    #           S() << ...,,
    #           S() << ...
    #           ...
    #         )
    #       }
    #     }
    #   end
    #
    # @example S can receive tag and block, and it can use as variable.
    #   core.config_ast do |ast, syn|
    #     syn.within {
    #       register_syntax('ast.name') {
    #         S(:example) { S() << E(..) << E(..) }
    #         SS(
    #           S(:example) << A(..),
    #           S(:example) << ...,
    #           S(:example) << ...
    #           ...
    #         )
    #       }
    #     }
    #   end
    #
    # @example Action can be aggragated to add. name is OK to be set or not set.
    #   core.config_ast do |ast, syn|
    #     syn.within {
    #       register_syntax('ast.name', A(:na)) {
    #         SS(
    #           S() << E(..) << E(..),
    #           S() << ...,,
    #           S() << ...
    #           ...
    #         )
    #       }
    #     }
    #   end
    #
    # @api public
    # @note please see Example page for further example
    # rubocop:disable all
    def register_syntax(name_or_action = nil, action = nil, &blk)
      return unless block_given?

      if name_or_action.nil?
        name = @ast.name
      else
        if name_or_action.is_a?(String)
          name = name_or_action
        else
          if action.nil?
            action = name_or_action
          else
            application_error 'it seems that name_or_action is not a String but action is given.'\
              ' This is a Parameter Error.'
          end
        end
      end

      arrs = blk.call
      if depth(arrs) == 1
        arrs = [arrs]
      end

      return if arrs.nil?

      if action.nil?
        arrs.each_with_index do |arr, i|
          match = T.must(arr[0..-2])
          action_ = T.must(arr[-1..-1])
          qualifier_ = nil
          if arr[-2].instance_of? Qualifier
            match = T.must(arr[0..-3])
            action_ = T.must(arr[-1..-1])
            qualifier_ = T.must(arr[-2])
          end

          if !action_[0].is_a? ActionBase
            application_error 'provided syntax mismatch class type => Action'
          end

          action_[0].register_qualifier(qualifier_)
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

    private

    def depth(array)
      return 0 unless array.is_a?(Array)

      return 1 + depth(array[0])
    end
  end
end
