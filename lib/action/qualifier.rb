# typed:true
# frozen_string_literal:true

require_relative 'action_base'
require_relative '../log'
require_relative '../exception'
require 'sorbet-runtime'

module SheepAst
  # This class is for the action to recprd the result
  class Qualifier < SheepObject
    extend T::Sig
    include Log
    include Exception

    def initialize(index, expr, not_ = true) # rubocop:disable all
      super()
      @index = index - 1
      @match_expr = expr
      @not = not_
    end

    def match(expr1, expr2)
      if expr1.instance_of? String
        expr1 == expr2
      else
        expr1 =~ expr2
      end
    end

    sig { params(data: AnalyzeData).returns(T::Boolean) }
    def qualify(data)
      ret = false
      if match(@match_expr, index_data(data, @index))
        ret = true
      end

      if @not
        ret = !ret
      end

      return ret
    end

    sig { params(data: AnalyzeData, index: Integer).returns(String) }
    def index_data(data, index)
      tokenized = T.must(T.must(data).file_info).tokenized
      line =     T.must(T.must(data).file_info).line
      offset =   T.must(T.must(data).file_info).index
      max_line = T.must(T.must(data).file_info).max_line

      expr = expr_get(tokenized, line, offset, max_line, index)

      ldebug "index data gets #{expr}, for line = #{line}, offset = #{offset},"\
        " max_line = #{max_line}, index = #{index}"
      return expr
    end

    def expr_get(tokenized, line, offset, max_line, index)
      line_ = line
      index_no = offset + index

      while line_ < max_line
        line_expr = tokenized[line_]
        return nil if line_expr.nil?

        if index_no < line_expr.length
          return line_expr[index_no]
        else
          index_no -= line_expr.length
        end

        line_ += 1
      end
    end
  end
end
