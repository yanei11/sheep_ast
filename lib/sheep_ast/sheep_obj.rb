# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'

module SheepAst
  # To define common definition of sheep object.
  # It is applied to be instanciated a lot in the sheep ast liibrary like
  #  MatchBase, ActionBase
  #
  #  @api private
  #
  class SheepObject
    extend T::Sig

    sig { returns(T.nilable(Integer)) }
    attr_accessor :my_id

    sig { returns(T.nilable(FactoryBase)) }
    attr_accessor :my_factory

    sig { returns(String) }
    attr_accessor :name

    sig { returns(String) }
    attr_accessor :domain

    sig { returns(String) }
    attr_accessor :full_name

    def initialize
      @name = T.must(self.class.name).split('::').last
    end

    def within(&blk)
      instance_eval(&blk)
    end
  end
end
