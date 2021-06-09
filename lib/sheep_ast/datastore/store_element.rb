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

    sig { returns(T.untyped) }
    attr_accessor :sub_data

    attr_reader :data
    attr_reader :meta

    sig {
      params(
        value: T.nilable(@@generic_primitive_type),
        hash: T::Hash[String, @@generic_primitive_type]
      ).void
    }
    def initialize(value, hash = {})
      @data = value
      @sub_data = nil
      @meta = hash
    end

    sig { params(value: @@generic_primitive_type).void }
    def keeplast(value)
      @data = value
    end

    sig { params(hash: T::Hash[T.any(Symbol, String), @@generic_primitive_type]).void }
    def add_meta(hash)
      @meta.merge!(hash)
    end

    sig {
      params(
        value: T.nilable(@@generic_primitive_type),
        hash: T::Hash[String, @@generic_primitive_type]
      ).void
    }
    def add_sub(value, hash)
      val = StoreSubElement.new(value, hash)
      if @sub_data.nil?
        @sub_data = []
      end

      if @sub_data.is_a? Hash
        application_error 'Default object is Hash'
      end

      @sub_data << val
    end

    def last_sub
      if @sub_data.is_a? Array
        return @sub_data.last
      end
    end

    sig {
      params(
        key: T.any(String, Symbol),
        value: StoreSubElement
      ).void
    }
    def keeplast_sub(key, value)
      if @sub_data.nil?
        @sub_data = {}
      end

      if @sub_data.is_a? Array
        application_error 'Default object is Array'
      end

      @sub_data[key] = value
    end

    def member(&blk)
      @sub_data&.each do |elem|
        blk.call(elem)
      end
      return nil
    end
  end

  # Sub storeing class for StoreElement
  class StoreSubElement
    extend T::Sig
    include Log
    include Exception
    include DataStoreTypeBase

    attr_reader :meta
    attr_reader :data

    sig {
      params(
        value: T.nilable(@@generic_primitive_type),
        hash: T::Hash[String, @@generic_primitive_type]
      ).void
    }
    def initialize(value, hash = {})
      @data = value
      @meta = hash
    end

    sig { params(value: @@generic_primitive_type).void }
    def keeplast(value)
      @data = value
    end

    sig { params(hash: T::Hash[T.any(Symbol, String), @@generic_primitive_type]).void }
    def add_meta(hash)
      @meta.merge!(hash)
    end

    def member(&blk)
      blk.call(self)
    end
  end
end
