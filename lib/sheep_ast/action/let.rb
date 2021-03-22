# typed: ignore
# frozen_string_literal:true

require_relative 'action_base'
require_relative 'let_redirect'
require_relative 'let_inspect'
require_relative 'let_compile'
require_relative 'let_record'
require_relative 'let_include'
require_relative 'let_helper'
require_relative 'let_operate_node'
require_relative 'let_operate_behavior'
require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module SheepAst
  # Let action instance
  #
  # @example
  #   A(:let, [funcion1, *para, **option], [function2, *para, **options]] ...
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
    include LetInclude
    include LetOperateNode
    include LetOperateBehavior

    sig { returns(T.any(T::Array[Symbol], T::Array[T::Array[Symbol]])) }
    attr_accessor :fsyms

    # To crate Let object
    #
    # Let object uses the function given by the symbol with processed data.
    # Pease refer to included module for the supported function such as
    # LetRedirect, LetRecord modules. Please refer to Let*** modules in this object
    #
    # @example
    #   A(:let, [:redirect, ...], [:record, ...], ...)
    #
    sig {
      params(
        fsyms: T.any(Symbol, T::Array[Symbol]),
        options: T.untyped
      ).returns(Let)
    }
    def new(*fsyms, **options)
      ins = Let.new
      ins.fsyms = fsyms
      return ins
    end

    # rubocop: disable all
    sig { override.params(data: AnalyzeData, node: Node).returns(MatchAction) }
    def action(data, node)
      @data = data
      @node = node
      @ret = MatchAction::Finish

      key_data = keyword_data(data)
      ldebug "let handle data #{key_data.inspect} to : "
      fsyms.each do |fsym|
        ret = nil
        m = fsym[0]
        para = []
        opt = {}
        if fsym.length > 1
          opt = fsym[-1]
          para = fsym[1..-2]
          if !opt.is_a?(Hash)
            para << opt
            opt = {}
          end
        end
        ldebug "Function : #{m}, para = #{para.inspect}"
        if para.nil? || para.empty?
          ret = T.unsafe(self).method(m).call(key_data, @data_store, **opt)
        else
          ret = T.unsafe(self).method(m).call(key_data, @data_store, *para, **opt)
        end

        if ret == true # rubocop:disable all
          if @_pwarn.nil?
            @_pwarn = true
            lwarn "Registered method = [#{method(m).name}] returned true."\
              'Follows methods are ignored.', :red
            lwarn 'Exited method loop. This message is printed only once per let object.', :red
          end
          break
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

    sig { returns(Time) }
    def ctime_get
      @action_factory.ctime
    end

    sig { params(data: AnalyzeData).returns(MatchBase) }
    def get_first_match(data)
      id_ = data.stack.first
      match = T.cast(match_factory.from_id(id_), MatchBase)

      return match
    end

    sig { params(data: AnalyzeData).returns(MatchBase) }
    def get_last_match(data)
      id_ = data.stack.last
      match = T.cast(match_factory.from_id(id_), MatchBase)

      return match
    end

    sig { params(data: AnalyzeData, key: Symbol).returns(MatchBase) }
    def get_match(data, key)
      test = data.stack_symbol.find_index { |i| i == key }

      id_ = data.stack[T.must(test)]
      match = T.cast(match_factory.from_id(id_), MatchBase)

      return match
    end
  end
end
