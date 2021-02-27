# typed:ignore
# frozen_string_literal:true

require_relative '../exception'
require_relative '../factory_base'
require_relative '../ast_manager'
require_relative '../tokenizer'
require_relative '../datastore'
require_relative '../sheep_obj'
require_relative '../stage_manager'
require_relative '../fof'
require_relative 'node_operation'
require 'optparse'
require 'pry'

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
    include NodeOperation

    @@option = nil
    @@optparse = nil

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
      @data_store = DataStore.new
      @tokenizer = Tokenizer.new
      @stage_manager = StageManager.new
      @file_manager = FileManager.new(@stage_manager, @tokenizer, @data_store)
      @fof = FoF.new(@data_store)
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
    # rubocop:disable all
    sig { params(logs: Symbol, options: T.nilable(T::Boolean)).returns(T::Boolean) }
    def report(logs = :pfatal, **options) 
      yield
      return true
    rescue => e
      bt = e.backtrace
      arr = []
      bt.each do |elem|
        test = elem.split(':')
        arr << "#{test[0].split('/')[-1]}:#{test[-2]}"
      end
      logf = method(logs)
      logf.call ''
      logf.call '---------------------------'
      logf.call '## report Got exception ##'
      logf.call '--------------------------'
      logf.call ''
      logf.call '## Exception Info'
      logf.call 'Message'
      logf.call "#{e.inspect}", :red
      logf.call 'BackTrace:'
      logf.call "#{arr.inspect}", :blue
      logf.call ''
      dump(logs)
      logf.call 'Exception was occured at analyzer core'
      if !ENV['SHEEP_DEBUG_PRY'].nil?
        logf.call 'Entering pry debug session'
        binding.pry # rubocop: disable all
      else
        logf.call 'Not entering pry debug session.'
        logf.call 'Please define SHEEP_DEBUG_PRY for entering pry debug session'
      end
      logf.call ''
      logf.call 'End of Report'
      logf.call '--------------------------'
      logf.call ''

      if options[:raise]
        raise
      end

      return false
    end

    # API to set search path to include files by {SheepAst::LetInclude} module
    def sheep_dir_path_set(arr)
      @data_store.assign(:_sheep_dir_path, arr)
    end

    # API to set exclude path to skip analysis by {SheepAst::LetInclude} module
    def sheep_exclude_dir_path_set(arr)
      @data_store.assign(:_sheep_exclude_dir_path, arr)
    end


    # API to set output directory for {SheepAst::LetCompile} module
    def sheep_outdir_set(path)
      @data_store.assign(:_sheep_outdir, path)
    end

    # API to set output directory for {SheepAst::LetCompile} module
    def sheep_template_dir_path_set(arr)
      @data_store.assign(:_sheep_template_dir, arr)
    end

    private

    # @api private
    #
    sig { void }
    def do_analyze
      if !ENV['SHEEP_RSPEC'] || !ENV['SHEEP_BIN'].nil?
        process_option
      else
       @@option = {}
      end

      dump(:pwarn) and return if @@option[:d]

      @file_manager.analyze do |data|
        @stage_manager.analyze_stages(data)
      end
    end

    # @api private
    #
    sig { params(file: String).returns(String) }
    def tokenize(file)
      tokenized = @tokenizer.feed_file(file)
      ldebug "start #{File.expand_path(file)}", :red
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
    sig { params(argv: T::Array[String]).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
    def self.option_parse(argv)
      if @@option.nil?
        @@option = {}
        @@optparse = OptionParser.new do |opt|
          opt.on(
            '-E array', Array,
            'Specify directories to exclude files'
          ) { |v| @@option[:E] = v }
          opt.on(
            '-I array', Array, 'Specify search directories for the include files'
          ) { |v| @@option[:I] = v }
          opt.on(
            '-d', 'Dump Debug information'
          ) { @@option[:d] = true }
          opt.on(
            '-r file', 'Specify configuration ruby file'
          ) { |v| @@option[:r] = v }
          opt.on(
            '-o path', 'outdir variable is set in the let_compile module'
          ) { |v| @@option[:o] = v }
          opt.on(
            '-t array', Array,
            'Specify search directories for the template files for let_compile module'
          ) { |v| @@option[:t] = v }
          opt.on_tail(
            '-h', '--help', 'show usage'
          ) { |v| @@option[:h] = true }
          opt.on_tail(
            '-v', '--version', 'show version'
          ) { |v| @@option[:v] = true }

          opt.parse!(argv)
        end
      end

      if @@option[:h]
        AnalyzerCore.usage
        exit
      end

      if @@option[:v]
        puts SheepAst::VERSION
        exit
      end

      return @@option
    end

    def self.usage
      if @@optparse
        puts ''
        puts "Usage: #{@@optparse.program_name} [options] arg1, arg2, ..."
        puts '    arg1, arg2, ... : specify files to parse.'
        puts ''
        @@optparse.banner = 'Available options :'
        puts @@optparse.help
        puts ''
      end
      lprint @@option.inspect
    end

    def self.option
      @@option
    end

    # api private
    #
    sig { void }
    def process_option
      AnalyzerCore.option_parse(ARGV)
      @@option[:D]&.each do |item|
        if item.include?('=')
          key = item.split('=').first
          data = item.split('=').last
          @envdb[key] = data
        else
          @envdb[item] = '1'
        end
      end

      sheep_dir_path_set(@@option[:I]) if @@option[:I]
      sheep_exclude_dir_path_set(@@option[:E]) if @@option[:E]
      sheep_outdir_set(@@option[:o]) if @@option[:o]
      sheep_template_dir_path_set(@@option[:t]) if @@option[:t]
    end
  end
end
