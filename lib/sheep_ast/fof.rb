# typed: strict
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require_relative 'datastore/datastore'
require_relative 'match/match_factory'
require_relative 'action/action_factory'

module SheepAst
  # Factory of factories
  #
  # @api private
  #
  class FoF
    extend T::Sig
    include Log
    include Exception
    include FactoryBase
    include UseMatchAlias
    include UseActionAlias

    sig { params(analyzer_core: AnalyzerCore, data_store: DataStore).void }
    def initialize(analyzer_core, data_store)
      @data_store = data_store
      @analyzer_core = analyzer_core
      super()
    end
  end
end
