# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module SheepAst
  # Let include module
  module LetRecord
    extend T::Sig
    extend T::Helpers

    # Record given key and value expression block to data store
    #
    # Syntax:
    # A(:let, [record_kv_by_id, :<store_id>, :<tag symbol for key>, :<tag symbol for value>, {options}]
    #
    # Specified data by key and value tag symbol will be stored to store_id symbol
    # Note that store_id tag symbol mast have `_H` post fix which denote it is a Hash map
    #
    # Options:
    # namespace <Boolean>  : if true, namespace is added in the form of ns1::ns2:: at the prefix of key
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        store_id: Symbol,
        key_id: Symbol,
        value_id: T.any(T::Array[Symbol], Symbol),
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def record_kv_by_id(pair, datastore, store_id, key_id, value_id, **options)
      value = nil
      if value_id.is_a? Enumerable
        value = []
        value_id.each { |elem| value << pair[elem] }
      else
        value = pair[value_id]
      end
      key = pair[key_id]
      namespace = pair[:_namespace]
      ldebug "store => '#{store_id}', key_id => '#{key_id}', value_id => '#{value_id}', "\
        "pair_data => '#{pair}', key_id => '#{key_id}', value_id => '#{value_id}', "\
        "key => '#{key}', value => '#{value}', namespace => '#{namespace}'"
      if options[:namespace]
        namespace.reverse_each do |elem|
          key = "#{elem}::#{key}"
        end
        ldebug "namespace added => #{key}"
      end
      datastore.assign(store_id, value, key)
    end

    alias record_kv record_kv_by_id

    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        store_id: Symbol,
        value_id: T.any(T::Array[Symbol], Symbol),
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def record(pair, datastore, store_id, value_id, **options)
      value = nil
      if value_id.is_a? Enumerable
        value = []
        value_id.each { |elem| value << pair[elem] }
      else
        value = pair[value_id]
      end
      ldebug "store => '#{store_id}', value_id => '#{value_id}', "\
        "pair_data => '#{pair}', value_id => '#{value_id}', "\
        "value => '#{value}'"
      datastore.assign(store_id, value)
    end

    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        store_id: Symbol,
        value_id: T.any(T::Array[Symbol], Symbol),
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def record_a(pair, datastore, store_id, value_id, **options)
      value = nil
      if value_id.is_a? Enumerable
        value = []
        value_id.each { |elem| value << pair[elem] }
      else
        value = pair[value_id]
      end
      ldebug "store => '#{store_id}', value_id => '#{value_id}', "\
        "pair_data => '#{pair}', value_id => '#{value_id}', "\
        "value => '#{value}'"
      datastore.assign(store_id, value)
    end
  end
end
