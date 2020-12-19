# typed: false
# frozen_string_literal:true

require_relative 'generation'
require_relative 'exception'
require 'rainbow/refinement'
require 'sorbet-runtime'
require 'set'

using Rainbow

module SheepAst
  # TBD
  class DataStore
    extend T::Sig
    include Exception
    include Log

    sig { void }
    def initialize
      @all_var = Set.new
      # @temp_var = {}
      super()
    end

    alias inspect_bak inspect

    sig { params(sym: Symbol, value: T.untyped, key: T.untyped).void }
    def assign(sym, value, key = nil) # rubocop: disable all
      t_sym = :"@#{sym}"

      is_defined = instance_variable_defined?(t_sym)

      if array_var(sym)
        usage and application_error 'trying to assing array with key' unless key.nil?
        instance_variable_set(t_sym, []) unless is_defined
        add(t_sym, value)
      elsif hash_l1_var(sym)
        usage and application_error 'trying to assign hash without key' if key.nil?
        instance_variable_set(t_sym, {}) unless is_defined
        add_pair(t_sym, key, value)
      elsif hash_var(sym)
        usage and application_error 'trying to assign hash without key' if key.nil?
        instance_variable_set(t_sym, {}) unless is_defined
        concat_pair(t_sym, key, value)
      elsif hash_arr_var(sym)
        usage and application_error 'trying to assign hash without key' if key.nil?
        instance_variable_set(t_sym, {}) unless is_defined
        add_arr_pair(t_sym, key, value)
      else
        unless key.nil?
          lfatal "key is not nil. Given sym should have _H suffix. sym = #{sym}"
          usage and application_error 'key is not nil, despite it is not enumerable'
        end
        instance_variable_set(t_sym, value)
      end

      unless is_defined
        @all_var << t_sym
        # if temporal_var(sym)
        #   @temp_var[t_sym] = t_sym
        # end
      end
    end

    sig { params(sym: Symbol).void }
    def remove(sym)
      t_sym = :"@#{sym}"
      # if temporal_var(sym)
      #   @temp_var.delete(t_sym)
      # end
      @all_var.delete(t_sym)
      remove_instance_variable(t_sym) if instance_variable_defined?(t_sym)
    end

    sig { params(sym: Symbol).returns(T.untyped) }
    def value(sym)
      return val(:"@#{sym}")
    end

    sig { void }
    def cleanup_all
      @all_var.each do |v|
        remove_instance_variable(v) if instance_variable_defined?(v)
      end
      @all_var = Set.new
    end

    sig { returns(String) }
    def usage
      lfatal ''
      lfatal 'Please make sure the suffix of the store_id'.yellow
      lfatal ''
      lfatal 'Usage ========================================='.yellow
      lfatal 'Use following store id depends on the types:'.yellow
      lfatal '  :xxx    - Hold single string'.yellow
      lfatal '  :xxx_A  - Hold Array of string'.yellow
      lfatal '  :xxx_H  - Hold Key Value pair of string. concat array, so dim is 1'.yellow
      lfatal '  :xxx_HA - Hold Key Value pair of string, push array so dim is 2'.yellow
      lfatal '  :xxx_HL - Hold Key and Last one Value pair of strin. One data'.yellow
      lfatal ''
      lfatal 'Note: let record_kv accept following kind:'.yellow
      lfatal '      xxx_H, xxx_HL, xxx_HA'.yellow
      lfatal '================================================'.yellow
      lfatal ''
    end

    def inspect
      "custom inspect : <#{self.class.name} object_id = #{object_id}, all_var = #{@all_var.inspect}>"
    end
    # sig { void }
    # def cleanup_tmp
    #   @temp_var.each do |_k, v|
    #     remove_instance_variable(v) if instance_variable_defined?(v)
    #     @all_var.delete(v)
    #   end
    #   @temp_var = {}
    # end

    sig { params(id: T.nilable(Symbol)).returns(T.untyped) }
    def dump_data(id = nil)
      data = {}
      if id.nil?
        @all_var.each do |elem|
          data[elem] = instance_variable_get(elem)
        end
      else
        data[id] = instance_variable_get(:"@#{id}")
      end
      return data
    end

    sig { params(id: T.nilable(Symbol)).void }
    def dump(id = nil)
      ldump dump_data(id).inspect
    end

    private

    sig { params(sym: Symbol).returns(T.untyped) }
    def val(sym)
      return instance_variable_get(sym)
    end

    sig { params(sym: Symbol, value: T.untyped).void }
    def add(sym, value)
      val(sym).send(:<<, value)
    end

    sig { params(sym: Symbol, key: T.untyped, value: T.untyped).void }
    def add_pair(sym, key, value)
      val(sym).send(:store, key, value)
    end

    sig { params(sym: Symbol, key: T.untyped, value: T.untyped).void }
    def concat_pair(sym, key, value)
      val_ = val(sym).send(:[], key)
      if val_.nil?
        val_ = []
      end
      if value.is_a? Enumerable
        val_.concat(value)
      else
        val_ << value
      end
      val(sym).send(:store, key, val_)
    end

    sig { params(sym: Symbol, key: T.untyped, value: T.untyped).void }
    def add_arr_pair(sym, key, value)
      val_ = val(sym).send(:[], key)
      if val_.nil?
        val_ = []
      end
      val_ << value
      val(sym).send(:store, key, val_)
    end

    # sig { params(sym: Symbol).returns(T::Boolean) }
    # def temporal_var(sym)
    #   return sym.to_s.start_with?('__')
    # end

    sig { params(sym: Symbol).returns(T::Boolean) }
    def array_var(sym)
      return sym.to_s.end_with?('_A')
    end

    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_var(sym)
      return sym.to_s.end_with?('_H')
    end

    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_l1_var(sym)
      return sym.to_s.end_with?('_HL')
    end

    sig { params(sym: Symbol).returns(T::Boolean) }
    def hash_arr_var(sym)
      return sym.to_s.end_with?('_HA')
    end
  end
end
