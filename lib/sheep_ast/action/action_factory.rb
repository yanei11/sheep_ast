# typed: true
# frozen_string_literal:true

require_relative '../log'
require_relative '../factory_base'
require_relative '../exception'
require_relative 'no_action'
require_relative 'let'

module SheepAst
  # Match fatiory
  class ActionFactory < SheepObject
    extend T::Sig
    include Log
    include Exception
    include FactoryBase

    sig { returns(DataStore) }
    attr_accessor :data_store

    sig { returns(AnalyzerCore) }
    attr_accessor :analyzer_core

    sig { void }
    def initialize
      super()
      @no_action = NoAction.new
      @let = Let.new
      @my_name = 'action_factory'
    end

    # Aggregated interface for the creation of the Action
    # This function is used from the syntax_alias like `A(:let, ...)`.
    #
    # rubocop: disable all
    sig { params(kind: Symbol, para: T.untyped, kwargs: T.untyped).returns(ActionBase) }
    def gen(kind, *para, **kwargs) # rubocop: disable all
      action =
        case kind
        when :na then @no_action.new(*para, **kwargs)
        when :let then @let.new(*para, **kwargs)
        else
          application_error 'unknown action'
        end

      create_id(action)
      action.data_store = @data_store
      action.analyzer_core = @analyzer_core
      action.action_factory = self
      action.match_factory = my_factory.match_factory
      return action
    end
  end

  # TBD
  module UseActionAlias
    extend T::Sig
    include Exception
    include FactoryBase

    def initialize
      @action_factory = ActionFactory.new
      @action_factory.my_factory = self
      application_error '@data_store is necessary' if data_store.nil?
      @action_factory.data_store = @data_store
      @action_factory.analyzer_core = @analyzer_core
      super()
    end
  end
end
