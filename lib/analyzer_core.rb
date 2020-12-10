# typed:ignore
# frozen_string_literal:true

require_relative 'exception'
require_relative 'factory_base'
require_relative 'ast_manager'
require_relative 'tokenizer'
require_relative 'datastore'
require_relative 'sheep_obj'
require_relative 'action/include_handler'
require_relative 'stage_manager'
require_relative 'fof'
require 'rainbow/refinement'
require 'optparse'

using Rainbow

module Sheep
  # TBD
  class AnalyzerCore < SheepObject # rubocop: disable all
    include Log
    include Exception
    extend T::Sig
    include FactoryBase

    sig { returns(StageManager) }
    attr_reader :stage_manager

    sig { returns(Tokenizer) }
    attr_reader :tokenizer

    sig { returns(IncludeHander) }
    attr_accessor :include_handler

    sig { returns(DataStore) }
    attr_accessor :data_store

    sig { void }
    def initialize
      @tokenizer = Tokenizer.new
      @include_handler = IncludeHandler.new
      @stage_manager = StageManager.new
      @file_manager = FileManager.new(@stage_manager, @tokenizer)
      @data_store = DataStore.new
      @fof = FoF.new(@data_store)
      @option = {}
      super()
    end

    sig { params(argv: T::Array[String]).void }
    def option(argv)
      OptionParser.new do |opt|
        opt.on(
          '-E [VALUE]', Array,
          'Specify directories for the files that should not be included'
        ) { |v| @option[:E] = v }
        opt.on(
          '-I [VALUE]', Array, 'Specify directories for the include files'
        ) { |v| @option[:I] = v }

        opt.parse!(argv)
        linfo "Application starts with option => #{@option.inspect.cyan}"
      end
    end

    sig { void }
    def parse_option
      @option[:D]&.each do |item|
        if item.include?('=')
          key = item.split('=').first
          data = item.split('=').last
          @envdb[key] = data
        else
          @envdb[item] = '1'
        end
      end

      @option[:I]&.each do |item|
        @include_handler.register_dir_path(item)
      end

      @option[:E]&.each do |item|
        @include_handler.register_exclude_dir_path(item)
      end
    end

    sig { returns Class }
    def let
      Let
    end

    sig { params(name: String).returns(AstManager) }
    def gen_ast(name)
      return AstManager.new(name, @data_store, @fof.match_factory)
    end

    def config_tok(&blk)
      blk.call(@tokenizer)
    end

    # sig { params(name: String, klass: AstManager, blk:
    #              T.
    def config_ast(name, klass = AstManager, &blk)
      if !name_defined?(name)
        ast = klass.new(name, @data_store, @fof.match_factory)
        create_id(ast, name)
        syn = Sheep::Syntax.new(ast, @fof.match_factory, @fof.action_factory)
        blk.call(ast, syn, @fof.match_factory, @fof.action_factory)
        @stage_manager.add_stage(ast)
      else
        ast = from_name(name)
        syn = Sheep::Syntax.new(ast, @fof.match_factory, @fof.action_factory)
        blk.call(ast, syn, @fof.match_factory, @fof.action_factory)
      end
      return ast
    end

    sig { params(files: T::Array[String]).void }
    def analyze_file(files)
      @files = files
      @file_manager.register_files(files)
      @file_manager.analyze do |data|
        @stage_manager.analyze_stages(data)
      end
    end

    sig { params(expr: String).void }
    def <<(expr)
      analyze_expr(expr)
    end

    sig { params(expr: String).void }
    def analyze_expr(expr)
      @file_manager.register_next_expr(expr)
      @file_manager.analyze do |data|
        @stage_manager.analyze_stages(data)
      end
    end

    sig { params(file: String).returns(String) }
    def tokenize(file)
      tokenized = @tokenizer.feed_file(file)
      ldebug "start #{File.expand_path(file).red}"
      return tokenized
    end

    sig { void }
    def disable_eof_validation
      @stage_manager.disable_eof_validation
    end

    sig { params(logs: Symbol).void }
    def dump(logs = :pfatal)
      @tokenizer.dump(logs)
      @stage_manager.dump_tree(logs)
    end

    sig { params(logs: Symbol, options: T.nilable(T::Boolean)).void }
    def report(logs = :pfatal, **options)
      yield
    rescue => e # rubocop: disable all
      bt = e.backtrace
      arr = []
      bt.each do |elem|
        test = elem.split(':')
        arr << "#{test[0].split('/')[-1]}:#{test[-2]}"
      end
      method(logs).call "exception is observe. detail => #{e.inspect}, bt => #{arr.inspect}".red
      dump(logs)
      if options[:raise]
        raise
      end
    end
  end
end
