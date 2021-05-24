# typed: strict
# frozen_string_literal:true

require 'sorbet-runtime'

module SheepAst
  class DataStore; end

  class StoreElement; end

  # Hold Sorbet Type alias
  module DataStoreTypeBase
    extend T::Sig

    attr_reader :data

    @@generic_store_type = T.any(
      String, T::Array[String],
      Integer, T::Array[Integer],
      Float, T::Array[Float],
      T::Boolean, T::Array[T::Boolean],
      StoreElement, T::Array[StoreElement],
      DataStore
    )

    @@generic_primitive_type = T.any(
      String,
      Integer,
      Float,
      T::Boolean
    )

    @@generic_store_element_type = T.any(
      String,
      Integer,
      Float,
      T::Boolean,
      StoreElement
    )
  end
end
