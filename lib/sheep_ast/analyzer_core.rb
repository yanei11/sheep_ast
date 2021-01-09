# typed:ignore
# frozen_string_literal:true

require_relative 'exception'
require_relative 'factory_base'
require_relative 'ast_manager'
require_relative 'tokenizer'
require_relative 'datastore'
require_relative 'sheep_obj'
require_relative 'stage_manager'
require_relative 'fof'
require 'rainbow/refinement'
require 'optparse'
require 'pry'

using Rainbow

# api public
module SheepAst
  # Aggregates User interface of sheep_ast library
  #
  # @api public
  class AnalyzerCore < SheepObject # rubocop: disable all
    include Log
    include Exception
    extend T::Sig
    include FactoryBase

    # @api private
    sig { returns(StageManager) }
    attr_accessor :stage_manager

    # @api private
    sig { returns(Tokenizer) }
    attr_accessor :tokenizer

    # Returns DataStore object
    # It holds user store data at the :record function in the Let action
    #
    # @api public
    sig { returns(DataStore) }
    attr_accessor :data_store

    # Constructor
    #
    # @example
    #   core = SheepAst::AnalyzerCore.new
    #
    sig { void }
    def initialize
      @tokenizer = Tokenizer.new
      @stage_manager = StageManager.new
      @file_manager = FileManager.new(@stage_manager, @tokenizer)
      @data_store = DataStore.new
      @fof = FoF.new(@data_store)
      @option = {}
      super()
    end

    # Return Let class object allow user to define method
    #
    # @example
    #   core.let.within {
    #     def user-defined-func
    #       # define inside the let class
    #     end
    #   }
    #
    sig { returns Class }
    def let
      Let
    end

    # To configure tokenizer
    #
    # @example
    #   core.config_tok do |tok|
    #     tok.some_ethod
    #   end
    #
    # @note Please see Example page for further usage
    #
    def config_tok(&blk)
      blk.call(@tokenizer)
    end

    # To configure AST objects.
    # Allow user to add AST analze
    #
    # @example
    #   core.config_ast do |ast, syn|
    #     syn.within {
    #       #..
    #     }
    #   end
    #
    # @note Please see Example page for further usage
    #
    def config_ast(name, klass = AstManager, &blk)
      if !name_defined?(name)
        ast = klass.new(name, @data_store, @fof.match_factory)
        create_id(ast, name)
        syn = SheepAst::Syntax.new(ast, @fof.match_factory, @fof.action_factory)
        blk.call(ast, syn, @fof.match_factory, @fof.action_factory)
        @stage_manager.add_stage(ast)
      else
        ast = from_name(name)
        syn = SheepAst::Syntax.new(ast, @fof.match_factory, @fof.action_factory)
        blk.call(ast, syn, @fof.match_factory, @fof.action_factory)
      end
      return ast
    end

    # To add file paths to anayze
    #
    # @raise
    #   Exception
    #
    # @example
    #   core.analyze_file([file1, file2, ...]
    #
    # @note report function is used with this
    #
    sig { params(files: T::Array[String]).void }
    def analyze_file(files)
      @files = files
      @file_manager.register_files(files)
      do_analyze
    end

    # To add expression to analyze
    #
    # @raise
    #   Exception
    #
    # @example
    #   core << "Some expression to analyze"
    #
    # @note report function is used with this
    #
    sig { params(expr: String).returns(AnalyzerCore) }
    def <<(expr)
      analyze_expr(expr)
      return self
    end

    # @api private
    #
    sig { params(expr: String).void }
    def analyze_expr(expr)
      @file_manager.register_next_expr(expr)
      do_analyze
    end

    # Dump information function
    # User can use this function to see the information
    #
    # @example
    #   core.dump
    #   # same output can be got by passing -d option to your program
    #
    sig { params(logs: Symbol).void }
    def dump(logs = :pfatal)
      logf = method(logs)
      @tokenizer.dump(logs)
      @stage_manager.dump_tree(logs)
      logf.call '## Resume Info ##'
      logf.call @file_manager.resume_data.inspect
      logf.call ''
    end

    # Handle exception
    # It can pass log function to use, Default is pfatal
    #
    # @example
    #   core.report {
    #     core.analyze_file(...)
    #   }
    #
    # @option raise [Boolean] :raise exception again if this is set to true
    #
    # @note If SHEEP_DEBUG_PRY is defined, pry debug session is started at the exception
    #
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
      logf = method(logs)
      logf.call "exception is observe. detail => #{e.inspect}, bt => #{arr.inspect}".red
      dump(logs)
      logf.call 'Exception was occured at analyzer core'
      if !ENV['SHEEP_DEBUG_PRY'].nil?
        logf.call 'Entering pry debug session'
        binding.pry # rubocop: disable all
      else
        logf.call 'Not entering pry debug session.'
        logf.call 'Please define SHEEP_DEBUG_PRY for entering pry debug session'
      end
      if options[:raise]
        raise
      end
    end

    private

    # @api private
    #
    sig { void }
    def do_analyze
      option(ARGV) unless ENV['SHEEP_RSPEC']
      dump(:pwarn) and return if @option[:d]

      @file_manager.analyze do |data|
        @stage_manager.analyze_stages(data)
      end
    end

    # @api private
    #
    sig { params(file: String).returns(String) }
    def tokenize(file)
      tokenized = @tokenizer.feed_file(file)
      ldebug "start #{File.expand_path(file).red}"
      return tokenized
    end

    # Not yet exposing function
    #
    # @api private
    #
    sig { void }
    def disable_eof_validation
      @stage_manager.disable_eof_validation
    end

    # Command line option
    #
    # @api private
    #
    # @example
    #   ruby your_app.rb -h # shows usage
    #
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
        opt.on(
          '-d', 'Dump Debug information'
        ) { @option[:d] = true }

        opt.parse!(argv)
        linfo "Application starts with option => #{@option.inspect.cyan}"
      end
    end

    # api private
    #
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

      @data_tore.assign(:_sheep_dir_path, @option[:I])
      @data_tore.assign(:_sheep_exclude_dir_path, @option[:E])
    end
  end
end
