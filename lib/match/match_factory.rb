# typed: false
# frozen_string_literal:true

require_relative '../log'
require_relative '../exception'
require_relative '../factory_base'
require_relative '../sheep_obj'
require_relative 'exact_match'
require_relative 'regex_match'
require_relative 'exact_group_match'
require_relative 'scoped_match'
require_relative 'enclosed_match'
require_relative 'enclosed_regex_match'
require_relative 'scoped_regex_match'

module SheepAst
  # Match fatiory
  class MatchFactory < SheepObject
    extend T::Sig
    include Log
    include Exception
    include FactoryBase

    sig { returns(DataStore) }
    attr_accessor :data_store

    sig { void }
    def initialize
      @exact_match = ExactMatch.new
      @regex_match = RegexMatch.new
      @exact_group_match = ExactGroupMatch.new
      @scoped_match = ScopedMatch.new
      @scoped_regex_match = ScopedRegexMatch.new
      @enclosed_match = EnclosedMatch.new
      @enclosed_regex_match = EnclosedRegexMatch.new
      @my_name = 'match_factory'
      super()
      # @regex_enlosed_match = RegexEnclosedMatch.new
    end

    sig { params(kind: Symbol, para: T.untyped, options: T.untyped).returns(MatchBase) }
    def gen(kind, *para, **options) # rubocop: disable all
      ldebug "kind = #{kind.inspect}, para = #{para.inspect}, options = #{options.inspect}"
      match =
        case kind
        when :e    then @exact_match.new(*para, **options)
        when :r    then @regex_match.new(*para, **options)
        when :eg   then @exact_group_match.new(*para, **options)
        when :sc   then @scoped_match.new(*para, **options)
        when :scr  then @scoped_regex_match.new(*para, **options)
        when :enc  then @enclosed_match.new(*para, **options)
        when :encr then @enclosed_regex_match.new(*para, **options)
        when :any  then @regex_match.new('.*', *para, **options)
        else
          application_error 'unknown match'
        end

      create_id(match)
      # match.data_store = @data_store
      match.kind_name_set(kind.to_s)
      return match
    end

    def gen_array(arr)
      gen(*arr)
    end
  end

  # TBD
  module UseMatchAlias
    extend T::Sig
    include Exception

    sig { returns(MatchFactory) }
    attr_accessor :match_factory

    sig { void }
    def initialize
      @match_factory = MatchFactory.new
      @match_factory.my_factory = self
      super()
    end
  end
end
