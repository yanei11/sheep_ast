# typed: true
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'
require_relative '../log'
require_relative '../messages'
require_relative 'let_helper'

using Rainbow

module SheepAst
  # Let include module
  module LetOperateBehavior
    extend T::Sig
    extend T::Helpers
    include LetHelper
    include Log

    # Record given key and value expression block to data store
    #
    # @api public
    #
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        ast_name: String,
        operation: OnOff,
        options: T.untyped
      ).returns(T.nilable(T::Boolean))
    }
    def operate_action(pair, datastore, ast_name, operation, **options)
      ldebug? and ldebug "operation Action #{operation.inspect} to #{ast_name.inspect}", :purple

      if operation == OnOff::Disable
        @analyzer_core.disable_action(ast_name)
      elsif operation == OnOff::Enable
        @analyzer_core.enable_action(ast_name)
      end

      return T.unsafe(self).ret(**options)
    end
  end
end
