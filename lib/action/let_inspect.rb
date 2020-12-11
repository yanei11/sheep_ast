# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'
require 'pry'

using Rainbow

module SheepAst
  # Let inclde module
  module LetInspect
    extend T::Sig
    extend T::Helpers

    # show variable data passed from the Let action
    #
    # Syntax:
    # A(:let, [:show, {options}]
    #
    # Options:
    # disable <Boolean>  : if true, it never prints
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def show(pair, datastore, **options)
      if !options[:disable]
        lprint "pair = #{pair.inspect}", :lightgreen
        lprint "datastore = #{datastore.inspect}", :lightgreen
        lprint "data = #{@data.inspect}", :lightgreen
      end
    end

    # Entering Debug shell pry
    #
    # Syntax:
    # A(:let, [:debug, {options}]
    #
    # Options:
    # disable <Boolean>  : if true, it never enter debug shell
    #
    # Environment variable:
    # SHEEP_LET_DISABLE_DEBUG    : debug is disable if it is defined
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def debug(pair, datastore, **options)
      if !options[:disable] && ENV['SHEEP_LET_DISABLE_DEBUG'].nil?
        binding.pry if _do_pry(**options) # rubocop:disable all
      end
    end

    sig {
      params(
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def _do_pry(**options)
      @count = 1 if @count.nil?
      @count += 1
      lprint "Entering debug mode, @count = #{@count}"
      return true
    end
  end
end
