# typed: false
# frozen_string_literal: true

require_relative 'exception'
require_relative 'file_manager'
require 'sorbet-runtime'

module SheepAst
  # Enum for kind of matcher
  class MatchKind < T::Enum
    include Exception

    enums do
      Exact = new
      ExactGroup = new
      Regex = new
      Condition = new
      RegexCondition = new
      Default = new
    end

    sig { returns(Integer) }
    def rank
      case self
      when Exact then 0
      when ExactGroup then 1
      when Regex then 2
      when Condition then 3
      when RegexCondition then 4
      else
        application_error
      end
    end
  end

  # Enum for action of matcher
  class MatchAction < T::Enum
    enums do
      Abort = new
      LazyAbort = new
      Next = new
      StayNode = new
      Continue = new
      InitContinue = new
      Finish = new
      Default = new
    end
  end

  # Enum for status of matcher
  class MatchStatus < T::Enum
    enums do
      NotFound = new
      ConditionMatchingStart = new
      ConditionMatchingProgress = new
      ConditionMatchingAtEnd = new
      MatchingProgress = new
      AtEnd = new
      Default = new
    end
  end

  # Enum for action of matcher
  class RequestNextData < T::Enum
    enums do
      Next = new
      Again = new
    end
  end

  # TBD
  class NodeInfo < T::Struct
    extend T::Sig
    prop :node_id, T.nilable(Integer), default: 0
    prop :match_id, T.nilable(Integer), default: nil
    prop :kind,   T.nilable(MatchKind), default: nil
    prop :status, MatchStatus, default: MatchStatus::Default
    prop :store_symbol, T.nilable(Symbol), default: nil

    sig { params(other: NodeInfo).void }
    def copy(other)
      @node_id = other.node_id.dup
      @match_id = other.match_id.dup
      @kind = other.kind.dup
      @status = other.status.dup
      @store_symbol = other.store_symbol.dup
    end

    sig { void }
    def init
      @node_id = 0
      @match_id = nil
      @kind = nil
      @status = MatchStatus::Default
      @store_symbol = nil
    end
  end

  # TBD
  class FileInfo < T::Struct
    extend T::Sig
    include Log

    prop :file, T.nilable(String), default: nil
    prop :raw_lines, T.nilable(T::Array[String]), default: nil
    prop :tokenized, T.nilable(T::Array[T::Array[String]]), default: nil
    prop :chunk, T.nilable(String), default: nil
    prop :line, Integer, default: 0
    prop :max_line, Integer, default: 0
    prop :index, Integer, default: 0
    prop :namespace_stack, T::Array[T.nilable(String)], default: []
    prop :ast_include, T.nilable(T::Array[T.any(String, Regexp)]), default: nil
    prop :ast_exclude, T.nilable(T::Array[T.any(String, Regexp)]), default: nil
    prop :new_file_validation, T::Boolean, default: false

    def copy(other)
      @file = other.file.dup
      @tokenized = other.tokenized.dup
      @chunk = other.chunk.dup
      @line = other.line.dup
      @max_line = other.max_line.dup
      @index = other.index.dup
      @namespace_stack = other.namespace_stack.dup
      @ast_include = other.ast_include.dup
      @ast_exclude = other.ast_exclude.dup
      @raw_lines = other.raw_lines.dup
      @new_file_validation = other.new_file_validation
      # lprint "#{self.class.name} copy is called. #{inspect}"
    end

    def init
      # lprint "#{self.class.name} init is called. #{inspect}"
      @file = nil
      @tokenized = nil
      @chunk = nil
      @line = 0
      @max_line = 0
      @index = 0
      @namespace_stack = []
      @ast_include = nil
      @ast_exclude = nil
      @raw_lines = nil
      @new_file_validation = false
    end

    # def takeover(other)
    #   @namespace_stack = other.namespace_stack.dup
    #   lprint "#{self.class.name} takeover is called. #{inspect}"
    # end

    sig { returns String }
    def inspect
      "custome inspect <#{self.class.name} object_id = #{object_id}, file = #{@file.inspect},"\
        " chunk = #{@chunk.inspect},"" line = #{@line.inspect}, max_line = #{@max_line.inspect},"\
        " index = #{@index.inspect}, namespace_stack = #{@namespace_stack.inspect},"\
        " ast_include = #{@ast_include.inspect}, ast_exclude = #{@ast_exclude.inspect},"\
        " new_file_validation = #{@new_file_validation.inspect}>"
    end
  end

  class SaveRequest < T::Struct
    prop :file, T.nilable(String), default: nil
    prop :chunk, T.nilable(T::Array[T::Array[String]]), default: nil
    prop :ast_include, T.nilable(T.any(String, T::Array[T.any(String, Regexp)])), default: nil
    prop :ast_exclude, T.nilable(T.any(String, T::Array[T.any(String, Regexp)])), default: nil
    prop :namespace, T.nilable(T.any(String, Symbol)), default: nil
  end

  # TBD
  class AnalyzeData < T::Struct
    extend T::Sig
    prop :expr, T.nilable(String), default: nil
    prop :tokenized_line, T.nilable(T::Array[String]), default: nil
    prop :raw_line, T.nilable(String), default: nil
    prop :file_info, T.nilable(FileInfo), default: nil
    prop :file_manager, T.nilable(FileManager), default: nil
    prop :stack, T::Array[Integer], default: []
    prop :stack_symbol, T::Array[T.nilable(Symbol)], default: []
    prop :request_next_data, RequestNextData, default: RequestNextData::Next
    prop :save_request, T.nilable(SaveRequest), default: nil

    def init
      @expr = nil
      @tokenized_line = nil
      @file_info = nil
      @file_manager = nil
      @request_next_data = RequestNextData::Next
      @stack = []
      @stack_symbol = []
      @save_request = nil
      @raw_line = nil
    end

    sig { returns(String) }
    def inspect
      return "custom inspect <#{self.class.name} object_id = #{object_id},"\
        " expr = '#{expr.inspect}', stack = #{stack.inspect}, stack_symbol = #{stack_symbol.inspect},"\
        " request_next_data = #{request_next_data.inspect}, file_info = #{file_info.inspect},"\
        " raw_line = #{@raw_line.inspect}"
    end
  end
end
