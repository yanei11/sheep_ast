# typed:true
# frozen_string_literal:true

require_relative 'log'
require 'sorbet-runtime'

module SheepAst
  # utility to perform deep copy for Hash or Array
  module DeepCopy
    extend T::Sig
    include Exception
    include Log
    @@deep_copy_max_depth = 10

    sig {
      params(obj: T.any(Hash, Array, Integer, String),
             repeate_count: Integer)
        .returns(T.any(Hash, Array, Integer, String))
    }
    def deep_copy(obj, repeate_count = 0)
      if repeate_count == @@deep_copy_max_depth
        lfatal 'Could be infinie loop \
                  Debug => obj:' + obj.inspect
        application_error
      end
      repeate_count += 1

      new_obj = nil
      if obj.respond_to?(:key?)
        # Hash case
        new_obj = {}
        obj.hash do |key, item|
          new_obj[key] = deep_copy(item, repeate_count)
        end
      elsif obj.respond_to?('each')
        # Array
        new_obj = []
        obj.hash do |item|
          new_obj << deep_copy(item, repeate_count)
        end
      else
        # Other type
        new_obj = obj.dup
      end
      return new_obj
    end
  end
end
