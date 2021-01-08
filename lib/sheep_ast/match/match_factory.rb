# typed: true
# frozen_string_literal:true

require_relative '../log'
require_relative '../exception'
require_relative '../factory_base'
require_relative '../sheep_obj'
require_relative 'exact_match'
require_relative 'any_match'
require_relative 'regex_match'
require_relative 'exact_group_match'
require_relative 'scoped_match'
require_relative 'enclosed_match'
require_relative 'enclosed_regex_match'
require_relative 'scoped_regex_match'

module SheepAst
  # Aggregated interface for the Matcher
  #
  # The user syntax like E(:e, ...) will be send to the #gen method.
  # The gen method calls Object's new method.
  #
  # For the current supported Match kind and options please see links from
  # the #initialize method's [View source] pull down.
  #
  # @see #gen
  # @see #initialize
  #
  class MatchFactory < SheepObject
    extend T::Sig
    include Log
    include Exception
    include FactoryBase

    sig { void }
    def initialize
      @exact_match = ExactMatch.new
      @any_match = AnyMatch.new
      @regex_match = RegexMatch.new
      @exact_group_match = ExactGroupMatch.new
      @scoped_match = ScopedMatch.new
      @scoped_regex_match = ScopedRegexMatch.new
      @enclosed_match = EnclosedMatch.new
      @enclosed_regex_match = EnclosedRegexMatch.new
      @my_name = 'match_factory'
      super()
    end

    # Aggregated interface for the creation of the Match
    # This function is used from the syntax_alias like `E(:e, 'test')`.
    #
    # rubocop: disable all
    sig { params(kind: Symbol, para: T.untyped, options: T.untyped).returns(T.any(T::Array[MatchBase], MatchBase)) }
    def gen(kind, *para, **options)
      ldebug "kind = #{kind.inspect}, para = #{para.inspect}, options = #{options.inspect}"

      match_arr = []
      repeat = options[:repeat].nil? ? 1..1 : 1..options[:repeat]

      repeat.each {
        match =
          case kind
          when :e    then @exact_match.new(*para, **options)
          when :r    then @regex_match.new(*para, **options)
          when :eg   then @exact_group_match.new(*para, **options)
          when :sc   then @scoped_match.new(*para, **options)
          when :scr  then @scoped_regex_match.new(*para, **options)
          when :enc  then @enclosed_match.new(*para, **options)
          when :encr then @enclosed_regex_match.new(*para, **options)
          when :any  then @any_match.new('any', *para, **options)
          when :eof  then @exact_match.new('__sheep_eof__', *para, **options)
          else
            application_error 'unknown match'
          end

        create_id(match)
        # match.data_store = @data_store
        match.kind_name_set(kind.to_s)
        match_arr << match
      }

      if match_arr.length == 1
        return T.cast(match_arr[0], MatchBase)
      else
        return match_arr
      end
    end
  end

  # @private
  module UseMatchAlias
    extend T::Sig
    include Exception

    sig { returns(MatchFactory) }
    attr_accessor :match_factory

    sig { void }
    def initialize
      @match_factory = MatchFactory.new
      @match_factory.my_factory = T.cast(self, FactoryBase)
      super()
    end
  end
end
