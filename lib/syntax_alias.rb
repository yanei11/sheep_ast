# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'

module Sheep
  # utility to perform deep copy for Hash or Array
  module SyntaxAlias
    extend T::Sig

    sig {
      params(
        para: T.any(String, Symbol),
        kwargs: T.any(T::Boolean)
      ).returns(T::Array[T.any(JSON::Ext::Generator::GeneratorMethods::String, Symbol)])
    }
    def stx(*para, **kwargs)
      return [*para, **kwargs] # rubocop:disable all
    end

    sig {
      params(
        para: T.any(String, Symbol),
        kwargs: T.any(T::Boolean)
      ).returns(T::Array[T.any(JSON::Ext::Generator::GeneratorMethods::String, Symbol)])
    }
    def exp(*para, **kwargs)
      return [*para, **kwargs] # rubocop:disable all
    end

    # sig {
    #   params(
    #     para: T.any(String, Symbol),
    #     kwargs: T.any(T::Boolean)
    #   ).returns(T::Array[T.any(Stringm, Symbol)])
    # }
    def E(*para, **kwargs) # rubocop:disable all
      return [*para, **kwargs] # rubocop:disable all
    end

    def _S(*para, **kwargs) # rubocop:disable all
      return []
    end

    def _SS(*para, **kwargs) # rubocop:disable all
      return para
    end

    def _SS_pushback(action, &blk) #rubocop:disable all
      arr = blk.call
      arr.each do |elem|
        elem << action
      end
      return arr
    end

    def A(kind, *para, **kwargs) # rubocop:disable all
      @af.gen(kind, *para, **kwargs)
    end

    sig { returns T::Array[String] }
    def crlf
      return [:e, "\r\n"]
    end

    sig { returns T::Array[String] }
    def lf
      return [:e, "\n"]
    end

    sig { returns T::Array[String] }
    def eof
      return [:e, '__sheep_eof__']
    end

    sig { returns T::Array[String] }
    def space
      return [:e, ' ']
    end

    sig { returns T::Array[String] }
    def cpp_comment
      return [:e, '//']
    end

    sig { returns T::Array[String] }
    def any
      return [:r, '.*']
    end
  end
end
