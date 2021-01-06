# typed: strict
# frozen_string_literal:true

require_relative 'action_base'
require 'sorbet-runtime'

module SheepAst
  # Action which does not do specific things
  class NoAction < ActionBase
    include T::Sig
    extend T::Helpers

    # NoAction action instance
    #
    # @example
    #   _S << E(...) <<  .. << A(:na)
    #
    # It does not do specific action.
    # So, the AST process is just done and it works as ignoreing the rule,
    # but it is found and results not raise NotFound error
    sig { params(para: T.untyped, options: T.untyped).returns(SheepAst::ActionBase) }
    def new(*para, **options)
      return NoAction.new
    end

    sig { override.params(_data: AnalyzeData, _node: Node).returns(MatchAction) }
    def action(_data, _node)
      return MatchAction::Finish
    end
  end
end
