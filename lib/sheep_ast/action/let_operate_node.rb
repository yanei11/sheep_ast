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
  module LetOperateNode
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
        ast_name: T.nilable(String),
        operation: OperateNode,
        options: T.untyped
      ).returns(T.nilable(T::Boolean))
    }
    def operate_node(pair, datastore, ast_name, operation, **options)
      ldebug? and ldebug "Node operation #{operation.inspect} to #{ast_name}"
      if @analyzer_core.nil?
        application_error 'analyzer_core must be set'
      end
      @analyzer_core.move_node(ast_name, operation)

      return T.unsafe(self).ret(**options)
    end
  end
end
