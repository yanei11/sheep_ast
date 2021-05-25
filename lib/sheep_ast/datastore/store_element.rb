# typed: ignore
# frozen_string_literal:true

require_relative '../log'
require_relative '../exception'
require_relative 'datastore_type_base'

module SheepAst
  # Factory of factories
  #
  # @api private
  #
  class StoreElement
    extend T::Sig
    include Log
    include Exception
    include DataStoreTypeBase

    sig { params(value: T.nilable(@@generic_primitive_type), hash: T::Hash[String, @@generic_primitive_type]).void }
    def initialize(value, hash = {})
      @data = value
      @meta = hash
    end

    sig { params(value: @@generic_primitive_type).void }
    def keeplast(value)
      @data = value
    end

    sig { params(key: String, value: @@generic_primitive_type).void }
    def add_meta(key, value)
      @meta[key] = value
    end

    sig { params(key: String).returns(T.nilable(@@generic_primitive_type)) }
    def meta(key)
      @meta[key]
    end
  end
end
