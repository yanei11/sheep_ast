# typed: true
# frozen_string_literal: true

require 'sorbet-runtime'

module Sheep
  # Matcher base class
  class SheepObject
    extend T::Sig

    sig { returns(T.nilable(Integer)) }
    attr_accessor :my_id

    sig { returns(T.nilable(FactoryBase)) }
    attr_accessor :my_factory

    sig { returns(T.nilable(String)) }
    attr_accessor :name

    sig { returns(T.nilable(String)) }
    attr_accessor :domain

    sig { returns(T.nilable(String)) }
    attr_accessor :full_name

    def initialize
      @name = T.must(self.class.name).split('::').last
    end

    def within(&blk)
      instance_eval(&blk)
    end
  end
end
