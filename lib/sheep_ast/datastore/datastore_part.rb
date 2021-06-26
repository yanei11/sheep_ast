# typed: ignore
# frozen_string_literal:true

require_relative '../exception'
require_relative 'store_element'
require_relative 'datastore_type_base'
require 'sorbet-runtime'

module SheepAst
  # Common method for Data Store Part objects
  module DataStoreCommonUtil
    def each(&blk)
      @data&.each(&blk)
    end

    def deep_copy
      Marshal.load(Marshal.dump(self))
    end

    def clear
      @data = nil
    end
  end

  # Common method for hash variable
  module HashUtil
    include DataStoreTypeBase
    extend T::Sig

    sig {
      params(
        key: T.untyped,
        options: T.untyped
      ).returns(T.nilable(@@generic_store_element_type))
    }
    def find(key, **options)
      elem = @data[key]

      if elem.nil? && !options[:allow_not_found]
        application_error "Specified key = #{key} has nil value"
      end

      return elem
    end

    sig {
      params(
        key: T.untyped,
        options: T.untyped
      ).returns(T.nilable(@@generic_store_element_type))
    }
    def nilable_find(key, **options)
      elem = @data[key]
      return elem
    end

    def delete(key)
      @data.delete(key)
    end
  end

  # Common method for hash in hash variable
  module HashHashUtil
    include DataStoreTypeBase
    extend T::Sig

    sig {
      params(
        key1: T.untyped,
        options: T.untyped
      ).returns(T.nilable(T::Hash[T.any(Symbol, String), @@generic_store_element_type]))
    }
    def find_hash(key1, **options)
      return @data[key1]
    end

    def each(&blk)
      @data&.each do |k1, hash|
        hash&.each do |k2, v|
          blk.call(k1, k2, v)
        end
      end
    end

    def delete_if_all_elem(&blk)
      delete_key1 = []
      delete_key2 = []
      @data&.each do |k1, hash|
        hash&.each do |k2, v|
          if blk.call(k1, k2, v)
            delete_key2 << [k1, k2]
          end
        end
      end

      if @data
        delete_key2.each do |elem|
          hash = @data[elem[0]]
          hash.delete(elem[1])
          if hash.size.zero?
            delete_key1 << elem[0]
          end
        end
        delete_key1.each do |elem|
          @data.delete(elem)
        end
      end
    end

    def delete_if(key1, &blk)
      delete_key1 = []
      delete_key2 = []
      if @data
        hash = @data[key1]
        hash&.each do |k2, v|
          if blk.call(k2, v)
            delete_key2 << [key1, k2]
          end
        end

        delete_key2.each do |elem|
          hash = @data[elem[0]]
          hash.delete(elem[1])
          if hash.size.zero?
            delete_key1 << elem[0]
          end
        end
        delete_key1.each do |elem|
          @data.delete(elem)
        end
      end
    end

    def delete(key1, key2s)
      res = false
      if !key2s.is_a? Enumerable
        key2s = [key2s]
      end

      if @data
        hash = @data[key1]
        key2s.each do |k2|
          res = hash&.delete(k2)
        end

        if hash&.size&.zero?
          @data.delete(key1)
        end
      end
      return res
    end

    sig {
      params(
        key1: String,
        key2: T.untyped,
        options: T.untyped
      ).returns(T.nilable(@@generic_store_element_type))
    }
    def find(key1, key2, **options)
      elem = try_find(key1, key2)
      if elem.nil?
        application_error "Specified key1 = #{key1}, key2 = #{key2} has nil value."\
          ' Use nilable_find if you accept nil'
      end

      return elem
    end

    sig {
      params(
        key1: String,
        key2: T.untyped,
        options: T.untyped
      ).returns(T.nilable(@@generic_store_element_type))
    }
    def nilable_find(key1, key2, **options)
      elem = try_find(key1, key2)
      return elem
    end

    sig { params(key1: T.nilable(String), key2: T.nilable(String)).void }
    def remove(key1 = nil, key2 = nil)
      if key1.nil? && key2.nil?
        @data = nil
        return
      end

      if key1 && key2
        @data[key1].delete(key2)
      else
        @data.delete(key1)
      end
    end

    def try_find(key1, key2)
      if @data.nil?
        @data = {}
      end

      v1 = @data[key1]
      if v1.nil?
        return nil
      end

      v2 = v1[key2]
      if v2.nil?
        return nil
      end

      return v2
    end

    def find_or_init(key1, key2, value = nil)
      if @data.nil?
        @data = {}
      end

      v1 = @data[key1]
      if v1.nil?
        d = { key2 => value }
        e = { key1 => d }
        @data.merge!(e)
        return false, value
      end

      v2 = v1[key2]
      if v2.nil?
        v1[key2] = value
        return false, value
      end

      return true, v2
    end
  end

  # Hold Array type value
  class DataStoreArray
    extend T::Sig
    include Exception
    include DataStoreCommonUtil
    include DataStoreTypeBase

    sig { void }
    def initialize
      @data = []
    end

    sig {
      params(
        elem: @@generic_store_type
      ).void
    }
    def add(elem)
      if @data.nil?
        @data = []
      end
      @data << elem
    end

    alias push add

    sig { returns(@@generic_store_type) }
    def pop
      @data.pop
    end

    sig { returns(T.nilable(@@generic_store_type)) }
    def last
      @data.last
    end

    def find(key)
      @data.each do |elem|
        if elem == key
          return elem
        end
      end
      return nil
    end
  end

  # Hold Hash type value. If array is given, it is concat
  class DataStoreHashCat
    extend T::Sig
    include Exception
    include DataStoreTypeBase
    include DataStoreCommonUtil
    include HashUtil

    sig { void }
    def initialize
      @data = {}
    end

    sig {
      params(
        key: T.untyped,
        value: @@generic_store_type
      ).void
    }
    def cat(key, value)
      if !@data.key?(key)
        @data[key] = []
      end

      if value.is_a? String
        @data[key] << value
      else
        @data[key].concat(value)
      end
    end
  end

  # Hold Hash type value. If array is given, it is added, not concat
  class DataStoreHashAdd
    extend T::Sig
    include Exception
    include DataStoreTypeBase
    include DataStoreCommonUtil
    include HashUtil

    sig { void }
    def initialize
      @data = {}
    end

    sig {
      params(
        key: T.untyped,
        value: @@generic_store_type
      ).void
    }
    def add(key, value)
      if @data.nil?
        @data = {}
      end

      if !@data.key?(key)
        @data[key] = []
      end

      @data[key] << value
    end

    alias push add

    sig { params(key: String).returns(@@generic_store_type) }
    def pop(key)
      @data[key].pop
    end

    sig { params(key: String)..returns(@@generic_store_type) }
    def last(key)
      @data[key].last
    end
  end

  # Hold Hash type value. It holds only latest one value
  class DataStoreHashLast
    extend T::Sig
    include Exception
    include DataStoreTypeBase
    include DataStoreCommonUtil
    include HashUtil

    sig { void }
    def initialize
      @data = {}
    end

    sig {
      params(
        key: T.untyped,
        value: @@generic_store_type
      ).void
    }
    def keeplast(key, value)
      if @data.nil?
        @data = {}
      end
      @data[key] = value
    end
  end

  # Hold Hash type value. Hold Hash inside Hash. Last one value is only hold
  class DataStoreHashHash
    extend T::Sig
    include Exception
    include DataStoreTypeBase
    include DataStoreCommonUtil
    include HashHashUtil

    sig {
      params(
        key1: String,
        key2: T.untyped,
        value: @@generic_store_element_type
      ).void
    }
    def keeplast(key1, key2, value)
      find, = find_or_init(key1, key2, value)
      if find
        @data[key1][key2] = value
      end
    end
  end

  # Hold Hash type value. Hold Hash inside Hash. Array value is hold
  class DataStoreHashHashArray
    extend T::Sig
    include Exception
    include DataStoreTypeBase
    include DataStoreCommonUtil
    include HashHashUtil

    sig {
      params(
        key1: String,
        key2: T.untyped,
        value: @@generic_store_element_type
      ).void
    }
    def add(key1, key2, value)
      find_or_init(key1, key2, [])
      @data[key1][key2] << value
    end
  end
end
