# typed: false
# frozen_string_literal:true

require_relative '../log'
require_relative '../exception'

# api public
module SheepAst
  # Aggregates User interface of sheep_ast library
  #
  # @api public
  module ActionOperation
    include Log
    include Exception
    extend T::Sig

    sig { params(name: String).void }
    def disable_action(name)
      @stage_manager.stage_get(name).ast.disable_action
    end

    sig { params(name: String).void }
    def enable_action(name)
      @stage_manager.stage_get(name).ast.enable_action
    end
  end
end
