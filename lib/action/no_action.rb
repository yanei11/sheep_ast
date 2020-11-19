# typed: true
# frozen_string_literal:true

require_relative 'action_base'
require 'sorbet-runtime'

module Sheep
  # TBD
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
