# typed: strict
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require_relative 'datastore'
require_relative 'match/match_factory'
require_relative 'action/action_factory'

module SheepAst
  # Factory of factories
  class FoF
    extend T::Sig
    include Log
    include Exception
    include FactoryBase
    include UseMatchAlias
    include UseActionAlias

    sig { returns(DataStore) }
    attr_accessor :data_store

    sig { params(data_store: DataStore).void }
    def initialize(data_store)
      @data_store = data_store
      super()
    end
  end
end
