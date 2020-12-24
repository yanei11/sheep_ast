# typed: true
# frozen_string_literal:true

require_relative 'action/qualifier'
require_relative 'match/index_condition'
require 'sorbet-runtime'

module SheepAst
  # syntax wrapper to allow user to use syntax easily.
  # This simplifies syntax user should input
  #
  # @api public
  #
  module SyntaxAlias
    extend T::Sig

    def E(kind, *para, **kwargs) # rubocop:disable all
      @mf.gen(kind, *para, **kwargs)
    end

    def _S(*para, **kwargs) # rubocop:disable all
      elem = []
      elem.instance_eval {
        def <<(elem)
          if elem.is_a? Enumerable
            T.unsafe(self).concat(elem)
          else
            T.unsafe(self).push(elem)
          end
        end
      }
      return elem
    end

    def _SS(*para, **kwargs) # rubocop:disable all
      return para
    end

    def A(kind, *para, **kwargs) # rubocop:disable all
      @af.gen(kind, *para, **kwargs)
    end

    def NEQ(expr, index = 1) # rubocop:disable all
      Qualifier.new(expr, offset: index)
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

    sig { params(par: T.untyped, options: T.untyped).returns(IndexCondition) }
    def idx(*par, **options)
      T.unsafe(IndexCondition).new(*par, **options)
    end
  end
end
