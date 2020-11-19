# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module Sheep
  # TBD
  module LetRecord
    extend T::Sig
    extend T::Helpers
    def record_kv_by_id(pair, datastore, store_id, key_id, value_id, **options)
      value = pair[value_id]
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
  end
end
