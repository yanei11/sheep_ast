# typed: strict
# frozen_string_literal:true

require_relative '../log'
require_relative '../exception'
require_relative 'store_element'
require_relative 'datastore_type_base'
require 'sorbet-runtime'

module SheepAst
  # Common method for hash variable
  module HashFind
    extend T::Sig

    def find(key)
      if @data.is_a? Hash
        return @data[key]
      end
    end
  end

  # Hold Array type value
  class DataStoreArray
    extend T::Sig
    include Log
    include Exception
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
      @data << elem
    end
  end

  # Hold Hash type value. If array is given, it is concat
  class DataStoreHashCat
    extend T::Sig
    include Log
    include Exception
    include HashFind
    include DataStoreTypeBase

    sig { void }
    def initialize
      @data = {}
    end

    sig {
      params(
        key: String,
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
    include Log
    include Exception
    include HashFind
    include DataStoreTypeBase

    sig { void }
    def initialize
      @data = {}
    end

    sig {
      params(
        key: String,
        value: @@generic_store_type
      ).void
    }
    def add(key, value)
      if !@data.key?(key)
        @data[key] = []
      end

      @data[key] << value
    end
  end

  # Hold Hash type value. It holds only latest one value
  class DataStoreHashLast
    extend T::Sig
    include Log
    include Exception
    include HashFind
    include DataStoreTypeBase

    sig { void }
    def initialize
      @data = {}
    end

    sig {
      params(
        key: String,
        value: @@generic_store_type
      ).void
    }
    def keeplast(key, value)
      @data[key] = value
    end
  end

  # Hold Hash type value. Hold Hash inside Hash. Last one value is only hold
  class DataStoreHashHash
    extend T::Sig
    include Log
    include Exception
    include DataStoreTypeBase

    sig { void }
    def initialize
      @data = Hash.new { |h, k| h[k] = {} }
    end

    sig {
      params(
        key1: String,
        key2: String,
        value: @@generic_store_element_type
      ).void
    }
    def keeplast(key1, key2, value)
      @data[key1][key2] = value
    end

    sig {
      params(
        key1: String,
        key2: String
      ).returns(@@generic_store_element_type)
    }
    def find(key1, key2)
      @data[key1][key2]
    end

    sig { params(key1: T.nilable(String), key2: T.nilable(String)).void }
    def remove(key1 = nil, key2 = nil)
      if key1.nil? && key2.nil?
        @data = Hash.new { |h, k| h[k] = {} }
        return
      end

      if key1 && key2
        @data[key1].delete(key2)
      else
        @data.delete(key1)
      end
    end
  end
end
