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

    attr_reader :sub_data
    attr_reader :data

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

    sig { params(value: T.nilable(@@generic_primitive_type)).void }
    def keeplast(value)
      @data = value
    end

    sig { params(hash: T::Hash[T.any(Symbol, String), T.untyped]).void }
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

    sig {
      params(
        search: @@generic_primitive_type,
        from_index: Integer
      ).returns(T.nilable(StoreSubElement))
    }
    def find_sub(search, from_index = 0)
      @sub_data&.each_with_index do |elem, index|
        if index >= from_index && elem.data == search
          return elem
        end
      end
      return nil
    end

    sig {
      params(
        searh: @@generic_primitive_type,
        from_index: Integer
      ).void
    }
    def find_sub_index(search, from_index = 0)
      @sub_data&.each_with_index do |elem, index|
        if index >= from_index && elem.data == search
          return elem, index
        end
      end
      return nil, nil
    end

    sig {
      params(
        index: Integer,
        value: T.nilable(@@generic_primitive_type),
        hash: T::Hash[String, @@generic_primitive_type]
      ).void
    }
    def replace_sub(index, value, hash)
      val = StoreSubElement.new(value, hash)
      @sub_data[index] = val
    end

    sig { returns(T.nilable(T.nilable(StoreSubElement))) }
    def last_sub
      if @sub_data.is_a? Array
        return @sub_data.last
      end

      return nil
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

    def member_with_index(&blk)
      @sub_data&.each_with_index do |elem, index|
        blk.call(elem, index)
      end
      return nil
    end

    def member(&blk)
      @sub_data&.each do |elem|
        blk.call(elem)
      end
      return nil
    end

    sig { params(store_element: StoreElement).void }
    def merge_sub(store_element)
      store_element&.member do |elem|
        add_sub(elem.data, elem.meta_get)
      end
    end

    sig { params(index: Integer).void }
    def delete_sub(index)
      @sub_data.delete_at(index)
    end

    sig { void }
    def clear_sub_all
      @sub_data = []
    end

    sig { params(key: T.any(String, Symbol)).returns(T.untyped) }
    def meta(key)
      @meta[key]
    end

    sig {
      returns(T::Hash[String, T.untyped])
    }
    def copy_meta
      @meta.dup
    end

    sig { returns(StoreElement) }
    def make_copy
      other = StoreElement.new(@data.dup)
      other.add_meta(copy_meta)
      member do |sub|
        other.add_sub(sub.data.dup, sub.copy_meta)
      end
      return other
    end

    sig { returns(Integer) }
    def sub_size
      size = @sub_data&.size
      size = 0 if size.nil?
      return size
    end
  end

  # Sub storeing class for StoreElement
  class StoreSubElement
    extend T::Sig
    include Log
    include Exception
    include DataStoreTypeBase

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

    sig { params(hash: T::Hash[T.any(Symbol, String), T.untyped]).void }
    def add_meta(hash)
      @meta.merge!(hash)
    end

    sig { params(key: T.any(String, Symbol)).returns(T.untyped) }
    def meta(key)
      @meta[key]
    end

    sig {
      returns(T.untyped)
    }
    def meta_get
      @meta
    end

    sig {
      returns(T::Hash[String, T.untyped])
    }
    def copy_meta
      @meta.dup
    end

    def member(&blk)
      blk.call(self)
    end
  end
end
