# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require 'sorbet-runtime'

module SheepAst
  # This class is for the action to recprd the result
  module DataIndexHandle
    extend T::Sig

    sig {
      params(
        data: AnalyzeData, index: Integer, newline: T.nilable(T::Boolean)
      ).returns(T.nilable(String))
    }
    def index_data(data, index, newline = nil)
      tokenized = T.must(T.must(data).file_info).tokenized
      line =     T.must(T.must(data).file_info).line
      offset =   T.must(T.must(data).file_info).index
      max_line = T.must(T.must(data).file_info).max_line

      application_error if index.zero?
      index -= 1
      application_error 'index is minus value' if index.negative?

      expr = expr_get(tokenized, line, offset, max_line, index, newline)

      ldebug "index data gets #{expr}, for line = #{line}, offset = #{offset},"\
        " max_line = #{max_line}, index = #{index}, expr = #{expr}"
      return expr
    end

    def expr_get(tokenized, line, offset, max_line, index, newline) # rubocop:disable all
      line_ = line
      index_no = offset + index
      expr_ = nil

      while line_ < max_line
        line_expr = tokenized[line_]
        expr_ = nil and break if line_expr.nil?

        expr_ = line_expr[index_no]
        if newline.nil? && expr_ == "\n"
          index_no += 1
        end

        if index_no < line_expr.length
          break
        else
          index_no -= line_expr.length
          if line_expr.include?("\n")
            index_no += 1 if newline.nil? && expr_ != "\n" # rubocop:disable all
          end
        end

        line_ += 1
      end
      ldebug "Hit info: line = #{line_}, index_no = #{index_no}, line_expr = #{expr_.inspect}"
      return expr_
    end
  end

  # This class is for the action to recprd the result
  module DataHandle
    extend T::Sig
    include Log
    include Exception
    include DataIndexHandle

    sig {
      params(
        exprs: T.any(NilClass, String, Regexp, T::Array[T.any(String, Regexp)]),
        options: T.untyped
      ).void
    }
    def data_handle_init(exprs, **options)
      @exprs = exprs.is_a?(Enumerable) ? exprs : [exprs]
      offset = options[:offset]
      @include_newline = options[:includ_newline]
      @offset = offset.nil? ? 1 : offset
    end

    sig { params(data: AnalyzeData).returns(T::Boolean) }
    def validate(data)
      @exprs.each_with_index do |expr, idx|
        idata = index_data(data, @offset + idx, @include_newline)
        if !match_(expr, idata)
          ldebug "validate fail: #{expr} is not hit for #{idata}"
          return false
        else
          ldebug "validte ok: #{expr}"
        end
      end
      return true
    end

    def match_(expr1, expr2)
      if expr1.instance_of? String
        expr1 == expr2
      else
        expr1 =~ expr2
      end
    end
  end
end
