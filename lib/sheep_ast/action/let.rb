# typed: ignore
# frozen_string_literal:true

require_relative 'action_base'
require_relative 'let_redirect'
require_relative 'let_inspect'
require_relative 'let_compile'
require_relative 'let_record'
require_relative 'let_helper'
require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module SheepAst
  # Let action instance
  #
  # Syntax:
  # A(:let, [funcion1, *para, **option], [function2, *para, **options]] ...
  #
  # This let data to handle given functions.
  # pre made API is included like LetRedirect module
  class Let < ActionBase
    extend T::Sig
    extend T::Helpers
    include Log
    include LetHelper
    include LetRedirect
    include LetInspect
    include LetCompile
    include LetRecord

    sig { returns(T.any(T::Array[Symbol], T::Array[T::Array[Symbol]])) }
    attr_accessor :fsyms

    sig {
      params(
        fsyms: T.any(Symbol, T::Array[Symbol]),
        kwargs: T.any(T::Boolean, Symbol, String)
      ).returns(Let)
    }
    def new(*fsyms, **kwargs)
      ins = Let.new
      ins.fsyms = fsyms
      return ins
    end

    sig { override.params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def action(data, node)
      @data = data
      @node = node
      @ret = MatchAction::Finish

      key_data = keyword_data(data)
      ldebug "let handle data #{key_data.inspect} to : "
      fsyms.each do |fsym|
        m = fsym[0]
        para = fsym[1..-1] #rubocop: disable all
        ldebug "Function : #{m}, para = #{para.inspect}"
        if para.nil? || para.empty?
          method(m).call(key_data, @data_store)
        else
          method(m).call(key_data, @data_store, *para)
        end
      end
      ldebug "let end. returns result = #{@ret}"

      return @ret
    end

    sig { override.returns(String) }
    def description
      str = "#{name}: "
      fsyms.each do |fsym|
        m = fsym[0]

        para = fsym[1..-1] #rubocop: disable all
        str += "Function : #{m}, para = #{para.inspect}, "
      end
      return str.chomp.chomp
    end

    def self.within(&blk)
      class_eval(&blk)
    end
  end
end
