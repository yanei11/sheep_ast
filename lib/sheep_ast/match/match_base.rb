# typed: true
# frozen_string_literal: true

require_relative '../log'
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
    include Exception
    include Log
    abstract!

    sig { returns(String) }
    attr_accessor :key

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

    sig { returns(T.nilable(T::Array[String])) }
    attr_accessor :ast_include

    sig { returns(T.nilable(T::Array[String])) }
    attr_accessor :ast_exclude

    sig { returns(T.nilable(T::Boolean)) }
    attr_accessor :at_end_cond

    sig { returns(T.nilable(T::Boolean)) }
    attr_accessor :at_cond_scope

    sig {
      params(
        key: String,
        sym: T.nilable(Symbol),
        options: T.untyped
      ).void
    }
    def initialize(key = '', sym = nil, **options)
      @key = key
      @regex_key = key.dup
      @store_sym = sym
      @options = options
      @debug = options[:debug]
      @extract = options[:extract]
      @start_add_cond = options[:index_cond]
      @end_add_cond = options[:end_cond]
      @command = options[:command] || key
      @description = options[:description]
      @my_tag = options[:tag]
      @regex_end = options[:regex_end]
      @end_match_index = options[:end_match_index]
      @start_match_index = options[:start_match_index]
      @at_head = @options[:at_head]
      @include = @options[:include]
      @not_include = @options[:not_include]
      @ast_include = @options[:ast_include]
      @ast_exclude = @options[:ast_exclude]
      @neq = @options[:neq]
      @neq = [@neq] if @neq.is_a? String
      @at_end_cond = false
      super()
    end

    sig { returns(String) }
    def inspect
      "custom inspect: <#{self.class.name} object_id = #{object_id}, kind_name = #{@kind_name},"\
        " key = #{@key}, start_line = #{@start_line}, end_line = #{@end_line},"\
        " matched_expr = #{@matched_expr.inspect} >"
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

    def self.check_exact_condition(map, key, data)
      m = map[key]
      m = nil if !m&.additional_cond(data)
      return m
    end

    def self.check_exact_group_condition(match, data)
      key = data.expr
      match.ldebug? and match.ldebug "check_exact_group_condition for #{T.must(key)}"
      match.keys.each do |item| #rubocop: disable all
        if key == item
          match.ldebug? and match.ldebug 'Found'
          return true
        end
      end
      match.ldebug? and match.ldebug "Not Found => group keys: #{match.keys.inspect}"
      return false
    end

    def self.check_regex_condition(match, data)
      res = match.match(data)
      if res
        match.ldebug? and match.ldebug 'check_regex_condition passed primary cond. Examin additional condition'
        if !match&.additional_cond(data)
          match.ldebug? and match.ldebug 'additional condition id not good'
          res = nil
        else
          match.ldebug? and match.ldebug 'additional condition is good'
          res = true
        end
      end
      return res
    end

    def self.check_any_condition(match, data)
      if !match&.additional_cond(data)
        match.ldebug? and match.ldebug 'additional condition id not good'
        res = nil
      else
        match.ldebug? and match.ldebug 'additional condition is good'
        res = true
      end
      return res
    end

    sig { params(data: AnalyzeData).returns(T.nilable(T::Boolean)) }
    def match(data)
      reg_match(@regex_key, T.must(data.expr))
    end

    sig { params(expr_: String, target_: String).returns(T.nilable(T::Boolean)) }
    def reg_match(expr_, target_)
      # expr = expr_.gsub(/\||\?|\*|\(|\)|\{|\}|\[|\]|\+|\./) { |word| "\\#{word}" }
      # target = target_.gsub(/\||\?|\*|\(|\)|\{|\}|\[|\]|\+|\./) { |word| "\\#{word}" }
      rg = Regexp.new expr_
      @md = rg.match(target_)
      ldebug? and ldebug @md.inspect
      if !@md.nil?
        ldebug? and ldebug 'Found'
        return true
      else
        ldebug? and ldebug 'Not Found'
        return nil
      end
    end

    def additional_cond(data) #rubocop:disable all
      if @at_head
        if data.file_info.index != 1
          ldebug? and ldebug 'at head : false'
          return false
        end
        ldebug? and ldebug 'at head : true'
      end

      if @include && !data.tokenized_line&.include?(@include)
        return false
      end

      if @not_include && data.tokenized_line&.include?(@not_include)
        return false
      end

      @neq&.each do |a_word|
        if data.expr == a_word
          return false
        end
      end

      ret = iterate_cond(data, @start_add_cond)
      ldebug? and ldebug "additional_cond : #{ret.inspect}"
      return ret
    end

    def additional_end_cond(data)
      ret = iterate_cond(data, @end_add_cond)
      ldebug? and ldebug "additional_end_cond : #{ret.inspect}"
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
      ldebug? and ldebug "matched_expr => #{@matched_expr.inspect}"
    end

    def validate(kind); end
  end
end
