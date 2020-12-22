# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require 'sorbet-runtime'

# TBD
module SheepAst
  # This class is for the action to recprd the result
  module DataIndexHandle
    extend T::Sig
    include Log
    include Exception

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

      application_error "index is invalid value: index = #{index}" if index.negative? || index.zero?

      ldebug "Current data: expr = #{tokenized[line][offset - 1]}, "\
        "for line = #{line}, offset = #{offset},"\
        " max_line = #{max_line}. From here to find expr after index = #{index}"

      expr = expr_get(tokenized, line, offset, max_line, index, newline)

      ldebug "Index at #{index} is  #{expr}, for line = #{line}, offset = #{offset},"\
        " max_line = #{max_line}"
      return expr
    end

    def expr_get(tokenized, line, offset, max_line, index, newline) #rubocop:disable all
      line_diff = 0
      to_index = index + offset - 1
      from_index = offset
      expr_test = nil
      @newline_count = 0

      while line + line_diff < max_line
        line_expr = tokenized[line + line_diff]

        expr_test = nil and break if line_expr.nil?

        expr_test = compute_expr(tokenized, line, from_index, to_index, newline, line_diff)

        break if !expr_test.nil?

        line_diff += 1
        from_index = 0
      end

      ldebug "Hit info: line = #{line_diff}, to_index = #{to_index}, "\
        "line_expr = #{expr_test.inspect}"

      return expr_test
    end

    def compute_expr(tokenized, line, from_index, to_index, newline, line_diff, number = 0) # rubocop: disable all
      line_expr = tokenized[line + line_diff]
      test_index = from_index + number
      number += 1

      ldebug "tokenized = #{tokenized.inspect}, line = #{line.inspect}, "\
        "from_index = #{from_index.inspect},"\
        " to_index = #{to_index.inspect}, number = #{number}, line_diff = #{line_diff}"

      if test_index - 1 > to_index + @newline_count
        application_error 'This is BUG case'
      end

      test_expr = line_expr[test_index]

      ldebug "test expr = #{test_expr.inspect}"

      return nil if test_expr.nil?

      if newline.nil? && test_expr == "\n"
        @newline_count += 1
      end

      offset = offset_get(tokenized, line, from_index, line_diff)

      ldebug "test_index + offset = #{test_index + offset}, "\
        "to_index + @newline_count = #{to_index + @newline_count}"

      if test_index + offset == to_index + @newline_count
        expr = line_expr[test_index]
        ldebug "Find the expression fullfilled given condition. expr = #{expr} !!"
        return expr
      end

      expr = compute_expr(tokenized, line, from_index, to_index, newline, line_diff, number)

      return expr
    end

    def offset_get(tokenized, line, index, line_diff)
      offset = 0
      (0..line_diff - 1).each do |num|
        offset += tokenized[line + num].length
      end
      return offset
    end

    def target_expr_get(tokenized, line, index, line_diff)
      offset = 0
      (0..line_diff - 1).each do |num|
        offset += tokenized[line + num].length
      end

      expr = tokenized[line + line_diff][index - offset + @newline_count]
      ldebug "target_expr is #{expr.inspect}, index = #{index}, offset = #{offset}, "\
        "line = #{line.inspect}, line_diff = #{line_diff.inspect}"

      return index - offset + @newline_count
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
