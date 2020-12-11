# typed:true
# frozen_string_literal:true

require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

module SheepAst
  # TBD
  module Generation
    extend T::Sig
    include Kernel

    sig { returns(Generation) }
    attr_accessor :parent

    sig { params(obj: Generation).void }
    def add_child(obj)
      @__generation_children = [] if @__generation_children.nil?

      @__generation_children.push(obj)
      obj.parent = self
    end

    sig { returns(Generation) }
    def top
      top_obj = self
      loop do
        break if top_obj.parent.nil?

        top_obj = top_obj.parent
      end

      return top_obj
    end

    sig { params(block: T.proc.params(arg0: Generation).void).void }
    def traverse(&block)
      @__generation_children.each do |a_child|
        block.call(a_child)
      end
    end
  end
end
