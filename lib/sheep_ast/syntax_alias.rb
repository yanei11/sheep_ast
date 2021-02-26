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
    include Kernel

    attr_accessor :s_db

    # Returns Match instance.
    # Please see register_syntax for the usage
    #
    # @see Syntax#register_syntax
    #
    # rubocop:disable all
    sig {
      params(
        kind: Symbol,
        para: T.untyped,
        options: T.untyped
      ).returns(
        T.any(MatchBase, T::Array[MatchBase])
      )
    }
    def E(kind, *para, **options)
      @mf.gen(kind, *para, **options)
    end

    # Holds array of Expressions and Action.
    # It can register it to the tag via block.
    # Please see register_syntax for the usage
    #
    # @see Syntax#register_syntax
    #
    # rubocop:disable all
    sig {
      params(
        index: Symbol,
        options: T.untyped,
        blk: T.nilable(T.proc.returns(
          T::Array[MatchBase]
        )),
      ).returns(
        T::Array[T.any(MatchBase, ActionBase)]
      )
    }
    def S(index = :root, **options, &blk)
      if @s_db.nil?
        @s_db = {}
        @s_db[:root] = []
      end

      elem = @s_db[index]&.dup || []

      elem.instance_eval {
        def <<(elem)
          if elem.is_a? Enumerable
            T.unsafe(self).concat(elem)
          else
            T.unsafe(self).push(elem)
          end
        end
      }

      #elem.parent_ref(self, index)
      if block_given?
        @s_db[index] = blk.call
      end

      return elem
    end


    # Holds array of Expressions and Action.
    # Please see register_syntax for the usage
    #
    # @see Syntax#register_syntax
    #
    # @deprecated
    #
    # rubocop:disable all
    sig { params(para: T.untyped, options: T.untyped).returns(T::Array[T.any(MatchBase, ActionBase)]) }
    def _S(*para, **options)
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

    # Holds array of _S.
    # Please see register_syntax for the usage
    #
    # @see Syntax#register_syntax
    #
    # rubocop:disable all
    sig { params(para: T.untyped, options: T.untyped).returns(T.untyped) }
    def _SS(*para, **options)
      return para
    end

    # Returns Action instance.
    # Please see register_syntax for the usage
    #
    # @see Syntax#register_syntax
    #
    # rubocop:disable all
    sig { params(kind: Symbol, para: T.untyped, options: T.untyped).returns(ActionBase) }
    def A(kind, *para, **options)
      @af.gen(kind, *para, **options)
    end

    # Returns Qualifier object.
    #
    # In the situation that Ast node has action and match to another node like:
    #
    # ```
    # root -> this_node -> this_action
    #                   -> another_node -> another_action
    # ```
    #
    # The qualification to continue node search or just do action is needed.
    # This function is to solve this issue.
    #
    # This function test next eqpression and execute following Action if the next action 
    #  is NOT equal to the expression.
    #
    # @example
    #   _SS(
    #     _S << E(:e, 'a') << E(:e, 'b') << NEQ('c') << A(...),
    #     _S << E(:e, 'a') << E(:e, 'b') << E(:e, 'c') << A(...)
    #   )
    #
    # @param expr [String] expressin to test
    # @param index [Integer] index to test. It test after index number expression
    #
    # rubocop:disable all
    sig { params(expr: String, index: Integer).returns(Qualifier) } 
    def NEQ(expr, index = 1)
      Qualifier.new(expr, offset: index)
    end

    sig { returns T.any(T::Array[SheepAst::MatchBase], SheepAst::MatchBase) }
    def crlf
      E(:e, "\r\n")
    end

    sig { returns T.any(T::Array[SheepAst::MatchBase], SheepAst::MatchBase) }
    def lf
      E(:e, "\n")
    end

    sig { returns T.any(T::Array[SheepAst::MatchBase], SheepAst::MatchBase) }
    def eof
      E(:e, '__sheep_eof__')
    end

    sig { returns T.any(T::Array[SheepAst::MatchBase], SheepAst::MatchBase) }
    def space
      E(:e, ' ')
    end

    sig { returns T.any(T::Array[SheepAst::MatchBase], SheepAst::MatchBase) }
    def cpp_comment
      E(:e, '//')
    end

    sig { params(tag: T.nilable(Symbol)).returns T.any(T::Array[SheepAst::MatchBase], SheepAst::MatchBase) }
    def any(tag = nil)
      tag.nil? ? E(:r, '.*') : E(:r, '.*', tag)
    end

    sig { params(par: T.untyped, options: T.untyped).returns(IndexCondition) }
    def idx(*par, **options)
      T.unsafe(IndexCondition).new(*par, **options)
    end

    # SS is the alias method of _SS
    alias_method :SS, :_SS
  end
end
