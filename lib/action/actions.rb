# typed:true
# frozen_string_literal:true

require_relative 'action_base'
require 'sorbet-runtime'

module Sheep
  # This class is for the action to recprd the result
  class Actions < ActionBase
    extend T::Sig

    sig { returns(T::Array[ActionBase]) }
    attr_accessor :myactions

    sig { void }
    def initialize
      super 'actions'
    end

    sig {
      params(actions: T::Array[ActionBase]).returns(Actions)
    }
    def new(actions)
      ins = Actions.new
      ins.myactions = actions
      return ins
    end

    sig { override.params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def action(data, node)
      myactions.each do |a_action|
        a_action.action(data, node)
      end
      return MatchAction::Finish
    end
  end
end
