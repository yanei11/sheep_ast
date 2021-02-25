# typed: true
# frozen_string_literal: true

require_relative '../exception'
require_relative '../messages'
require_relative '../sheep_obj'
require_relative '../data_handle_util'
require_relative 'match_util'
require 'sorbet-runtime'
require 'pry'

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
    attr_accessor :start_line

    sig { returns(Integer) }
    attr_accessor :start_index

    sig { returns(Integer) }
    attr_accessor :end_line

    sig { returns(Integer) }
    attr_accessor :end_index

    sig { returns(Integer) }
    attr_accessor :node_id

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :store_sym

    sig { returns(String) }
    attr_reader :kind_name

    sig { returns(Integer) }
    attr_accessor :my_chain_num

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :node_tag

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :parent_tag

    sig { returns(T.nilable(String)) }
    attr_accessor :description

    sig { returns(T.nilable(String)) }
    attr_accessor :command

    sig { returns(T.nilable(Symbol)) }
    attr_accessor :my_tag

    sig { params(name: String).void }
    def kind_name_set(name)
      @kind_name = name
    end

    sig {
      params(
        key: String,
        sym: T.nilable(Symbol),
        options: T.untyped
      ).void
    }
    def initialize(key = '', sym = nil, **options)
      @key = key
      @store_sym = sym
      @options = options
      @debug = options[:debug]
      @extract = options[:extract]
      @start_add_cond = options[:index_cond]
      @end_add_cond = options[:end_cond]
      @command = options[:command] || key
      @description = options[:description]
      @my_tag = options[:tag]
      super()
    end

    sig { returns(String) }
    def inspect
      "custom inspect: <#{self.class.name} object_id = #{object_id}, kind_name = #{@kind_name},"\
        " key = #{@key}, matched_expr = #{@matched_expr.inspect} >"
    end

    sig { params(data: AnalyzeData).void }
    def matched(data)
      expr_ = data.expr
      if @extract
        expr_ = T.must(expr_)[@extract]
      end

      if @store_sym.nil?
        @store_sym = "_#{my_chain_num}".to_sym
      end

      if @matched_expr.instance_of?(Array)
        @matched_expr.push(expr_)
      else
        @matched_expr = expr_
      end
      start_info_set(data.file_info&.line, data.file_info&.index)
      end_info_set(data.file_info&.line, data.file_info&.index)
    end

    def start_info_set(line, index)
      @start_line = line
      @start_index = index
    end

    def end_info_set(line, index)
      @end_line = line
      @end_index = index
    end

    sig { params(data: AnalyzeData).returns(T.nilable(T::Boolean)) }
    def match(data)
      reg_match(@key, T.must(data.expr))
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

    def additional_cond(data)
      if @options[:at_head]
        if data.file_info.index != 1
          ldebug 'at head : false'
          return false
        end
        ldebug 'at head : true'
      end

      ret = iterate_cond(data, @start_add_cond)
      ldebug "additional_cond : #{ret.inspect}"
      return ret
    end

    def additional_end_cond(data)
      ret = iterate_cond(data, @end_add_cond)
      ldebug "additional_end_cond : #{ret.inspect}"
      return ret
    end

    def iterate_cond(data, cond)
      return true if cond.nil?

      if cond.is_a? Enumerable
        cond.each do |c|
          ret = c.validate(data)
          return false if !ret
        end
      else
        ret = cond.validate(data)
        return false if !ret
      end

      return true
    end

    sig { abstract.void }
    def init; end

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
