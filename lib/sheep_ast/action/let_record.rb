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
    # @example
    #   A(:let, [record, <store_id>, <tag symbol for key or value>, [tag symbol for value], [options]]
    #
    # Specified key or value by tag symbol will be stored to store_id symbol.
    # If 4th parameter is not speified, then 3rd parameter is translated as value.
    #
    # It should have specific suffix: xxx_H, xxx_HA, xxx_HL, xxx_A, xxx(none suffix).
    # Please see DataStore object usage for the store_id symbol.
    #
    # If 4th parameter is specified, the store_id suffix should be xxx_H, xxx_HA, xxx_HL
    # If 4th parameter is not specified, the store_id suffix should be xxx_A, or xxx(none suffix).
    #
    # @option options [Boolean] :namespace if true, namespace is added in the form of 'ns1::ns2::' at the prefix of key
    #
    # @api public
    #
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        store_id: Symbol,
        k_or_v: T.any(T::Array[Symbol], Symbol),
        value: T.nilable(T.any(T::Array[Symbol], Symbol)),
        options: T.untyped
      ).void
    }
    def record(pair, datastore, store_id, k_or_v, value = nil, **options)
      if value.nil?
        record_v(pair, datastore, store_id, k_or_v, **options)
      else
        record_kv(pair, datastore, store_id, k_or_v, value, **options)
      end
    end

    # Please use record
    #
    # @deprecated
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        store_id: Symbol,
        key_id: Symbol,
        value_id: T.any(T::Array[Symbol], Symbol),
        options: T.untyped
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
      # value = data_shaping(value, options)
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

    # Please use record
    #
    # @deprecated
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        store_id: Symbol,
        value_id: T.any(T::Array[Symbol], Symbol),
        options: T.untyped
      ).void
    }
    def record_v(pair, datastore, store_id, value_id, **options)
      value = nil
      if value_id.is_a? Enumerable
        value = []
        value_id.each { |elem| value << pair[elem] }
      else
        value = pair[value_id]
      end
      # value = data_shaping(value, options)
      ldebug "store => '#{store_id}', value_id => '#{value_id}', "\
        "pair_data => '#{pair}', value_id => '#{value_id}', "\
        "value => '#{value}'"
      datastore.assign(store_id, value)
    end
  end
end
