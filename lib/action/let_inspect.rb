# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'
require 'pry'

using Rainbow

module Sheep
  # TBD
  module LetInspect
    extend T::Sig
    extend T::Helpers
    def show(pair, datastore, **options)
      if !options[:disable]
        lprint "pair = #{pair.inspect}", :lightgreen
        lprint "datastore = #{datastore.inspect}", :lightgreen
        lprint "data = #{@data.inspect}", :lightgreen
      end
    end

    def debug(pair, datastore, **options)
      if !options[:disable] && !ENV['SHEEP_LET_DEBUG'].nil?
        binding.pry if _do_pry(**options) # rubocop:disable all
      end
    end

    def _do_pry(**options)
      @count = 1 if @count.nil?
      @count += 1
      lprint "Entering debug mode, @count = #{@count}"
      return true
    end
  end
end
