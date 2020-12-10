# typed: true
# frozen_string_literal:true

require_relative 'action_base'
require 'sorbet-runtime'

module Sheep
  # NoAction action instance
  #
  # Syntax:
  # A(:na)
  #
  # It does not do specific action.
  # So, the AST process is just done and it works as ignoreing the rule,
  # but it is found and results not raise NotFound error
  class NoAction < ActionBase
    include T::Sig
    extend T::Helpers

    def new(*para, **kwargs)
      return NoAction.new
    end

    sig { override.params(_data: AnalyzeData, _node: Node).returns(MatchAction) }
    def action(_data, _node)
      return MatchAction::Finish
    end
  end
end
