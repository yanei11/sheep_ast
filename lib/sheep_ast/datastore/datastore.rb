# typed: true
# frozen_string_literal:true

require_relative '../exception'
require_relative 'cyclic_list'
require_relative 'datastore_part'
require 'sorbet-runtime'
require 'set'

module SheepAst
  # User can store data or fetch data from the object.
  # This is used by Let object's :record fuction
  #
  # @api public
  class DataStore
    extend T::Sig
    include Exception

    sig { returns(DataStore) }
    attr_reader :root

    # Constructor
    sig { params(root: T.nilable(DataStore)).void }
    def initialize(root = nil)
      @all_var = Set.new
      @ctime = Time.new
      @history = 5
      @root = root.nil? ? self : root
      # @temp_var = {}
      super()
    end

    sig { params(history: Integer).void }
    def history_set(history)
      @history = history
    end

    sig { returns(DataStore) }
    def top
      @root
    end

    sig { returns(DataStore) }
    def new
      DataStore.new(@root)
    end

    # General function to assigh value to given store_id and key
    #
    # @api private
    #
    # rubocop: disable all
    sig { params(sym: Symbol, value: T.untyped, key: T.untyped, key2: T.untyped).returns(T.untyped) }
    def assign(sym, value = nil, key = nil, key2 = nil)
      t_sym = :"@#{sym}"

      is_defined = instance_variable_defined?(t_sym)

      if array_var(sym)
        instance_variable_set(t_sym, DataStoreArray.new) unless is_defined
        add(t_sym, value) unless value.nil?
      elsif hash_l1_var(sym)
        instance_variable_set(t_sym, DataStoreHashLast.new) unless is_defined
        add_pair(t_sym, key, value) unless value.nil? || key.nil?
      elsif hash_var(sym)
        instance_variable_set(t_sym, DataStoreHashCat.new) unless is_defined
        concat_pair(t_sym, key, value) unless value.nil? || key.nil?
      elsif hash_arr_var(sym)
        instance_variable_set(t_sym, DataStoreHashAdd.new) unless is_defined
        add_arr_pair(t_sym, key, value) unless value.nil? || key.nil?
      elsif cyclic_list_var(sym)
        instance_variable_set(t_sym, CyclicList.new(@history)) unless is_defined
        add_list(t_sym, value) unless value.nil?
      elsif hash_hash_var(sym)
        instance_variable_set(t_sym, DataStoreHashHash.new) unless is_defined
        assign_hash(t_sym, key, key2, value) unless value.nil?
      elsif hash_hash_arr_var(sym)
        instance_variable_set(t_sym, DataStoreHashHashArray.new) unless is_defined
        assign_hash_arr(t_sym, key, key2, value) unless value.nil?
      else
        unless key.nil?
          puts "datastore> key is not nil. Given sym should have _H suffix. sym = #{sym}"
          usage and exit
        end

        if value.nil?
          puts "datastore> For this datastore type = #{sym}, value must be specified"
          usage and exit
        end

        instance_variable_set(t_sym, value)
      end

      unless is_defined
        @all_var << t_sym
      end

      if value.nil?
        return val(t_sym)
      end

      return nil
    end

    # remove by key symbol
    #
    # @api private
    #
    sig { params(sym: Symbol).void }
    def remove(sym)
      t_sym = :"@#{sym}"
      @all_var.delete(t_sym)
      remove_instance_variable(t_sym) if instance_variable_defined?(t_sym)
    end

    # get value from key symbol
    #
    # @api private
    #
    sig { params(sym: Symbol).returns(T.untyped) }
    def value(sym)
      return val(:"@#{sym}")
    end

    sig { params(sym: Symbol).returns(T.untyped) }
    def readclear(sym)
      obj = val(:"@#{sym}").dup
      remove(sym)
      return obj
    end

    alias search value

    # remove all the data
    sig { void }
    def cleanup_all
      @all_var.each do |v|
        remove_instance_variable(v) if instance_variable_defined?(v)
      end
      @all_var = Set.new
    end

    # usage print out.
    # Depends on the given store_id suffix, it switches data struture inside the object
    #  :xxx    - Hold single string
    #  :xxx_A  - Hold Array of string
    #  :xxx_H  - Hold Key Value pair of string. concat array, so dim is 1
    #  :xxx_HA - Hold Key Value pair of string, push array so dim is 2
    #  :xxx_HL - Hold Key and Last one Value pair of string
    #  :xxx_CL - Hold List with Cyclic history
    #
    # e.g. If user specify store_id as xxx_H then datastore object creates Hash object
    #      to allow user to prvide key/value pair to store the data
    #
    sig { void }
    def usage
      puts ''
      puts 'Please make sure the suffix of the store_id'
      puts ''
      puts 'Usage ========================================='
      puts '1. Use following store id depends on the types:'
      puts '  :xxx    - Hold single string'
      puts '  :xxx_A  - Hold Array of string'
      puts '  :xxx_H  - Hold Key Value pair of string. concat array'
      puts '  :xxx_HA - Hold Key Value pair of string, push array'
      puts '  :xxx_HL - Hold Key and Last one Value pair'
      puts '  :xxx_HHL - Hold Key1 and key2 and last value'
      puts '  :xxx_HHA - Hold Key1 and key2 and array value'
      puts '  :xxx_CL - Hold List with Cyclic history'
      puts ''
      puts '  Note: let record_kv accept following kind:'
      puts '        xxx_H, xxx_HL, xxx_HA'
      puts ''
      puts '2. Available API'
      puts '   - compile: To compile given file with datastore data'
      puts '================================================'
      puts ''
    end

    private

    # @api private
    #
    sig { params(sym: Symbol).returns(T.untyped) }
    def val(sym)
      return instance_variable_get(sym)
    end

    # @api private
    #
    sig { params(sym: Symbol, value: T.untyped).void }
    def add(sym, value)
      val(sym).send(:add, value)
    end

    # @api private
    #
    sig { params(sym: Symbol, key: T.untyped, value: T.untyped).void }
    def add_pair(sym, key, value)
      val(sym).send(:keeplast, key, value)
    end

    # @api private
    #
    sig { params(sym: Symbol, value: T.untyped).void }
    def add_list(sym, value)
      val(sym).send(:put, value)
    end

    # @api private
    #
    sig { params(sym: Symbol, key: T.untyped, value: T.untyped).void }
    def concat_pair(sym, key, value)
      val(sym).send(:cat, key, value)
    end

    # @api private
    #
    sig { params(sym: Symbol, key: T.untyped, value: T.untyped).void }
    def add_arr_pair(sym, key, value)
      val(sym).send(:add, key, value)
    end

    # @api private
    #
    sig { params(sym: Symbol, key1: T.untyped, key2: T.untyped, value: T.untyped).void }
    def assign_hash(sym, key1, key2, value)
      val(sym).send(:keeplast, key1, key2, value)
    end

    # @api private
    #
    sig { params(sym: Symbol, key1: T.untyped, key2: T.untyped, value: T.untyped).void }
    def assign_hash_arr(sym, key1, key2, value)
      val(sym).send(:add, key1, key2, value)
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def array_var(sym)
      return sym.to_s.end_with?('_A')
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_var(sym)
      return sym.to_s.end_with?('_H')
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_l1_var(sym)
      return sym.to_s.end_with?('_HL')
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_arr_var(sym)
      return sym.to_s.end_with?('_HA')
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def cyclic_list_var(sym)
      return sym.to_s.end_with?('_CL')
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_hash_var(sym)
      return sym.to_s.end_with?('_HHL')
    end

    # @api private
    #
    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_hash_arr_var(sym)
      return sym.to_s.end_with?('_HHA')
    end

    def ctime_get
      @ctime
    end
  end
end
