# typed: false
# frozen_string_literal: true

require_relative '../generation'
require_relative '../exception'
require_relative '../messages'
require_relative '../sheep_obj'
require_relative 'match_util'
require 'sorbet-runtime'

module SheepAst
  # Matcher base class
  class MatchBase < SheepObject
    extend T::Sig
    extend T::Helpers
    include Log
    include Exception
    abstract!

    sig { returns(String) }
    attr_reader :key

    sig { returns(T.any(T::Array[T.nilable(String)], T.nilable(String))) }
    attr_accessor :matched_expr

    sig { returns(Integer) }
    attr_accessor :node_id

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :store_sym

    sig { returns(String) }
    attr_reader :kind_name

    sig { returns(Integer) }
    attr_accessor :my_chain_num

    sig { params(name: String).void }
    def kind_name_set(name)
      @kind_name = name
    end

    sig { returns T.nilable(T::Hash[Symbol, T.any(T::Boolean, Symbol, String)]) }
    def options_get
      return @options
    end

    sig {
      params(
        key: String,
        sym: T.nilable(Symbol),
        options: T.nilable(T.any(T::Boolean, Symbol, String))
      ).void
    }
    def initialize(key = '', sym = nil, **options)
      @key = key
      @store_sym = sym
      @options = options
      super()
    end

    sig { returns(String) }
    def inspect
      "custom inspect: <#{self.class.name} object_id = #{object_id}, kind_name = #{@kind_name},"\
        " key = #{@key}, matched_expr = #{@matched_expr.inspect} >"
    end

    sig { params(data: AnalyzeData).void }
    def matched(data)
      if @store_sym.nil?
        @store_sym = "_#{my_chain_num}".to_sym
      end

      if @matched_expr.instance_of?(Array)
        @matched_expr.push(data.expr)
      else
        @matched_expr = data.expr
      end
    end

    sig { params(data: AnalyzeData).returns(T.nilable(T::Boolean)) }
    def match(data)
      reg_match(@key, data.expr)
    end

    sig { params(expr_: String, target_: String).returns(T.nilable(T::Boolean)) }
    def reg_match(expr_, target_)
      # expr = expr_.gsub(/\||\?|\*|\(|\)|\{|\}|\[|\]|\+|\./) { |word| "\\#{word}" }
      # target = target_.gsub(/\||\?|\*|\(|\)|\{|\}|\[|\]|\+|\./) { |word| "\\#{word}" }
      rg = Regexp.new expr_
      @md = rg.match(target_)
      ldebug @md.inspect
      if !@md.nil?
        ldebug 'Found'
        return true
      else
        ldebug 'Not Found'
        return nil
      end
    end

    sig { abstract.void }
    def init; end

    # sig { params(data: AnalyzeData).void }
    # def matched_end(data)
    #   if @store_sym.nil?
    #     return
    #   end

    #   # data.data[@store_sym] = data.expr
    # end

    sig { abstract.returns(MatchKind) }
    def kind?; end

    sig { returns(NodeInfo) }
    def node_info
      return NodeInfo.new(node_id: node_id, match_id: my_id, kind: kind?, store_symbol: store_sym)
    end

    sig { void }
    def dump
      ldebug "matched_expr => #{@matched_expr.inspect}"
    end
  end
end
