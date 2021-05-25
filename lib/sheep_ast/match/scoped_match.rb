# typed: false
# frozen_string_literal: true

require_relative 'scoped_match_base'
require 'sorbet-runtime'

module SheepAst
  # Scoped match instanc
  #
  # @see #new
  #
  class ScopedMatch < ScopedMatchBase
    extend T::Sig

    # @api private
    sig { params(expr1: String, expr2: String, data: AnalyzeData).returns(T.nilable(T::Boolean)) }
    def match_end(expr1, expr2, data)
      next_index = data.file_info.index
      check_data = expr2

      if @end_match_index
        check_index = next_index + @end_match_index - 1
        check_data = data.tokenized_line[check_index]
      end

      if @regex_end
        reg_match(expr1, check_data)
      else
        expr1 == check_data
      end
    end

    # @api private
    sig { params(expr1: String, expr2: String, data: AnalyzeData).returns(T.nilable(T::Boolean)) }
    def match_start(expr1, expr2, data)
      next_index = data.file_info.index
      check_data = expr2

      if @start_match_index
        check_index = next_index + @start_match_index - 1
        check_data = data.file_info.tokenized_line[check_index]
      end

      if kind? == MatchKind::Condition
        expr1 == check_data
      else
        reg_match(expr1, check_data)
      end
    end

    # @api private
    sig { override.returns(MatchKind) }
    def kind?
      return MatchKind::Condition
    end

    def validate(kind)
      if kind == :sc && @end_expr == "\n"
        # application_error "Use :endl or :endlr "
      end
    end
  end
end
