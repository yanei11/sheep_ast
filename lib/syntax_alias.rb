# typed: true
# frozen_string_literal:true

require_relative 'action/qualifier'
require 'sorbet-runtime'

module SheepAst
  # utility to perform deep copy for Hash or Array
  module SyntaxAlias
    extend T::Sig

    def E(kind, *para, **kwargs) # rubocop:disable all
      @mf.gen(kind, *para, **kwargs)
    end

    def _S(*para, **kwargs) # rubocop:disable all
      return []
    end

    def _SS(*para, **kwargs) # rubocop:disable all
      return para
    end

    def A(kind, *para, **kwargs) # rubocop:disable all
      @af.gen(kind, *para, **kwargs)
    end

    def NEQ(expr, index = 1) # rubocop:disable all
      Qualifier.new(index, expr)
    end

    sig { returns SheepAst::MatchBase }
    def crlf
      E(:e, "\r\n")
    end

    sig { returns SheepAst::MatchBase }
    def lf
      E(:e, "\n")
    end

    sig { returns SheepAst::MatchBase }
    def eof
      E(:e, '__sheep_eof__')
    end

    sig { returns SheepAst::MatchBase }
    def space
      E(:e, ' ')
    end

    sig { returns SheepAst::MatchBase }
    def cpp_comment
      E(:e, '//')
    end

    sig { params(tag: T.nilable(Symbol)).returns SheepAst::MatchBase }
    def any(tag = nil)
      tag.nil? ? E(:r, '.*') : E(:r, '.*', tag)
    end
  end
end
