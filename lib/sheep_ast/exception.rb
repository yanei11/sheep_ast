# typed: strict
# frozen_string_literal:true

require 'sorbet-runtime'

module SheepAst
  # Exception rase functions
  #
  # @api private
  #
  module Exception
    extend T::Sig
    include Kernel

    class MissingImpl < StandardError; end

    class ApplicationError < StandardError; end

    class NotFound < StandardError; end

    sig { params(msg: String).returns(T.noreturn) }
    def missing_impl(msg = 'missing implementation')
      ex = MissingImpl.new(msg)
      ex.set_backtrace(caller)
      raise ex
    end

    sig { params(msg: String).returns(T.noreturn) }
    def application_error(msg = 'Exception occured')
      ex = ApplicationError.new(msg)
      ex.set_backtrace(caller)
      raise ex
    end

    sig { params(msg: String).returns(T.noreturn) }
    def expression_not_found(msg = 'expression not found')
      ex = NotFound.new(msg)
      ex.set_backtrace(caller)
      raise ex
    end
  end
end
