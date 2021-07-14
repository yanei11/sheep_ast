# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require 'sorbet-runtime'

module SheepAst
  # utility function to handle Index of tokenized sentence.
  # This utility enable to compute expression from specified index.
  #
  # e.g. given tokenized sentence is  [[a, b, c, d, e, \n], [f, g, h, i, \n]] and
  #      given that you have matched expression d, then this utility allow user to
  #      give index 4 to specify 'h' word. It can handle multiline situation and
  #      defaultly it ignores '\n' newline indication
  #
  # @api private
  #
  module DataIndexHandle
    extend T::Sig
    include Log
    include Exception

    private

    sig {
      params(
        data: AnalyzeData, line_offset: Integer, index: Integer, newline: T.nilable(T::Boolean)
      ).returns(T.nilable(String))
    }
    def index_data(data, line_offset, index, newline = nil)
      tokenized = T.must(T.must(data).file_info).tokenized
      line =     T.must(T.must(data).file_info).line + line_offset
      offset =   T.must(T.must(data).file_info).index
      max_line = T.must(T.must(data).file_info).max_line

      offset = 0 unless line_offset.zero?

      application_error "index is invalid value: index = #{index}" if index.negative? || index.zero?

      ldebug? and ldebug "Current data: expr = #{tokenized&.[](line)&.[](offset - 1)}, "\
        "for line = #{line}, line_offset = #{line_offset}, offset = #{offset},"\
        " max_line = #{max_line}. From here to find expr after index = #{index}"

      expr = expr_get(tokenized, line, offset, max_line, index, newline)

      ldebug? and ldebug "Index at #{index} is  #{expr}, for line = #{line},"\
        " line_offset = #{line_offset}, offset = #{offset},"\
        " max_line = #{max_line}"
      return expr
    end

    # getting expression of specified index
    #
    # rubocop:disable all
    def expr_get(tokenized, line, offset, max_line, index, newline)
      line_diff = 0
      to_index = index + offset - 1
      from_index = offset
      expr_test = T.let(nil, T.untyped)
      @newline_count = 0

      while line + line_diff < max_line
        line_expr = tokenized[line + line_diff]

        break if line_expr.nil?

        expr_test = compute_expr(tokenized, line, from_index, to_index, newline, line_diff)

        break if !expr_test.nil?

        line_diff += 1
        from_index = 0
      end

      ldebug? and ldebug "Hit info: line = #{line_diff}, to_index = #{to_index}, "\
        "line_expr = #{expr_test.inspect}"

      return expr_test
    end

    # Core algorithm to compute expression
    #
    # rubocop: disable all
    def compute_expr(tokenized, line, from_index, to_index, newline, line_diff, number = 0)
      line_expr = tokenized[line + line_diff]
      test_index = from_index + number
      number += 1

      ldebug? and ldebug "tokenized = #{tokenized.inspect}, line = #{line.inspect}, "\
        "from_index = #{from_index.inspect},"\
        " to_index = #{to_index.inspect}, number = #{number}, line_diff = #{line_diff}"

      if test_index - 1 > to_index + @newline_count
        application_error 'This is BUG case'
      end

      test_expr = line_expr[test_index]

      ldebug? and ldebug "test expr = #{test_expr.inspect}"

      return nil if test_expr.nil?

      if newline.nil? && test_expr == '__sheep_eol__'
        @newline_count += 1
      end

      offset = offset_get(tokenized, line, from_index, line_diff)

      ldebug? and ldebug "test_index + offset = #{test_index + offset}, "\
        "to_index + @newline_count = #{to_index + @newline_count}"

      if test_index + offset == to_index + @newline_count
        expr = line_expr[test_index]
        ldebug? and ldebug "Find the expression fullfilled given condition. expr = #{expr} !!"
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
      ldebug? and ldebug "target_expr is #{expr.inspect}, index = #{index}, offset = #{offset}, "\
        "line = #{line.inspect}, line_diff = #{line_diff.inspect}"

      return index - offset + @newline_count
    end
  end

  # This module is used to handle AnalyzeData bject
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
      offset_line = options[:line_offset]
      @include_newline = options[:includ_newline]
      @offset = offset.nil? ? 1 : offset
      @offset_line = offset_line.nil? ? 0 : offset_line
    end

    sig { params(data: AnalyzeData).returns(T::Boolean) }
    def validate(data)
      @exprs.each_with_index do |expr, idx|
        idata = index_data(data, @offset_line, @offset + idx, @include_newline)
        if !match_dh(expr, T.must(idata))
          ldebug? and ldebug "validate fail: #{expr} is not hit for #{idata}"
          return false
        else
          ldebug? and ldebug "validte ok: #{expr}"
        end
      end
      return true
    end

    private

    sig { params(expr1: T.any(String, Regexp), expr2: String).returns(T::Boolean) }
    def match_dh(expr1, expr2)
      if expr1.instance_of? String
        if expr1 == expr2
          return true
        else
          return false
        end
      else
        if expr1 =~ expr2
          return true
        else
          return false
        end
      end
    end
  end
end
