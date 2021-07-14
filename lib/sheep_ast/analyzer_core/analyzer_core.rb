# typed: false
# frozen_string_literal:true

require_relative '../exception'
require_relative '../factory_base'
require_relative '../ast_manager'
require_relative '../tokenizer'
require_relative '../datastore/datastore'
require_relative '../sheep_obj'
require_relative '../stage_manager'
require_relative '../fof'
require_relative '../option'
require_relative 'node_operation'
require_relative 'action_operation'
require_relative '../datastore/compile'
require 'optparse'
require 'pry'

# api public
module SheepAst
  class AnalyzerCoreReturn < T::Struct
    prop :result, MatchResult, default: MatchResult::Default
    prop :eol, T::Boolean, default: true
    prop :next_command, T::Array[NextCommand], default: []
  end

  # Aggregates User interface of sheep_ast library
  #
  # @api public
  class AnalyzerCore < SheepObject # rubocop: disable all
    include Log
    include Exception
    extend T::Sig
    include FactoryBase
    include NodeOperation
    include ActionOperation
    include Option
    include DataStoreCompile

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
      @stage_manager = StageManager.new(@data_store)
      @file_manager = FileManager.new(@stage_manager, @tokenizer, @data_store)
      @fof = FoF.new(self, @data_store)
      @eol_validation = false
      @complete_callbacks = []
      @init_callbacks = []
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

    def config_syntax(name, klass = AstManager, &blk)
      if !name_defined?(name)
        ast = klass.new(name, @data_store, @fof.match_factory)
        create_id(ast, name)
        syn = SheepAst::Syntax.new(ast, @fof.match_factory, @fof.action_factory)
        blk.call(syn)
        @stage_manager.add_stage(ast)
      else
        ast = from_name(name)
        syn = SheepAst::Syntax.new(ast, @fof.match_factory, @fof.action_factory)
        blk.call(syn)
      end
      return ast
    end

    def add_handle_result(&blk)
      @result_blk = blk
    end

    sig { void }
    def handle_result
      @result_blk&.call(self, @data_store)
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
    sig { params(files: T.nilable(T::Array[String])).void }
    def analyze_file(files)
      analyze_init
      @files = files
      @file_manager.register_files(files)
      if !do_restore_datastore
        if !files.nil? && !files.empty?
          do_analyze
          do_dump
        else
          lwarn 'There is no given files'
        end
      else
        lwarn 'DataStore is restored. Skipped analyze files.'

        # Here we need to load option again.
        # Since datastore is loaded, loaded config maybe overwrited
        do_option(true)
      end
      complete_given_files
    end

    def add_complete_cb(callback)
      @complete_callbacks << callback
    end

    sig { void }
    def complete_given_files
      @complete_callbacks.each do |cb|
        t_cb = cb
        arg = nil
        if t_cb.is_a? String
          t_cb, arg = get_func_arg(cb)
        end
        let = Let.new
        if arg.nil?
          let.cb_action(t_cb, @data_store)
        else
          let.cb_action(t_cb, @data_store, arg)
        end
      end
    end

    def add_int_cb(callback)
      @init_callbacks << callback
    end

    sig { void }
    def analyze_init
      @init_callbacks.each do |cb|
        t_cb = cb
        arg = nil
        if t_cb.is_a? String
          t_cb, arg = get_func_arg(cb)
        end
        let = Let.new
        if arg.nil?
          let.cb_action(t_cb, @data_store)
        else
          let.cb_action(t_cb, @data_store, arg)
        end
      end
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
    sig { params(expr: String).returns(AnalyzerCoreReturn) }
    def <<(expr)
      analyze_expr(expr)
    end

    # @api private
    #
    sig { params(expr: String).returns(AnalyzerCoreReturn) }
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
      logf.call ''
      logf.call '## Resume Info ##'
      logf.call 'Current Processing Data'
      logf.call '- See above info', :magenta
      count = 0
      @file_manager.resume_data.reverse_each do |elem|
        count += 1
        logf.call ''
        logf.call '|\\'
        logf.call '|'
        logf.call "-- stack##{count} --"
        logf.call "- object_id = #{elem.object_id}"
        logf.call "- line = #{elem.line}"
        logf.call "- max_line = #{elem.max_line}"
        logf.call "- index = #{elem.index}"
        logf.call "- namespace_stack = #{elem.namespace_stack.inspect}"
        logf.call "- ast_include = #{elem.ast_include.inspect}"
        logf.call "- ast_exclude = #{elem.ast_exclude.inspect}"
        logf.call "- file = #{elem.file}"
      end
      logf.call ''
      logf.call ''
    end

    sig { params(file: String).void }
    def dump_store(file)
      DataStore.dump_store(file, @data_store)
    end

    sig { params(file: String).void }
    def load_store(file)
      @data_store = DataStore.load_store(file)
    end

    sig { void }
    def clear_store
      @data_store = nil
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
      logf.call '## Exception Info ##'
      logf.call 'Message:'
      logf.call "#{e.inspect}", :red
      logf.call 'BackTrace:'
      logf.call "#{arr.inspect}", :blue
      logf.call ''
      dump(logs)
      logf.call '## End of Report ##'
      logf.call 'Exception was occured at analyzer core'
      if !ENV['SHEEP_DEBUG_PRY'].nil?
        logf.call 'Entering pry debug session'
        binding.pry # rubocop: disable all
      else
        logf.call 'Define SHEEP_DEBUG_PRY for entering pry debug session here.'
      end
      logf.call ''
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

    # API to select files to include by {SheepAst::LetInclude} module
    def sheep_include_file_filter_set(arr)
      @data_store.assign(:_sheep_include_file_filter, arr)
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

    # API to raise exception when Lazy Abort
    def not_raise_when_all_ast_not_found
      @data_store.assign(:_sheep_not_raise_when_lazy_abort, true)
    end

    # To check last word, and if it is not matched, ignore the word
    # This is useful when console application's auto completion
    def enable_last_word_check(word = ' ')
      @file_manager.last_word_check = word
    end

    # disable last word check
    def disable_last_word_check
      @file_manager.last_word_check = nil
    end

    # If an action is called when it is not end of line
    # The action is ignored. This is useful for console application
    def enable_eol_validation
      @eol_validation = true
    end

    # disable eol validation
    def disable_eol_validation
      @eol_validation = false
    end

    sig { params(index: Integer).void }
    def do_dump(index = 1)
      arr = @option[:m]
      restore_file = nil
      restore_file = arr[index - 1] if arr

      if restore_file
        ldump "Stored DataStore information to #{restore_file}"
        dump_store(restore_file)
      end
    end

    private

    sig { params(name: String).returns(Stage) }
    def stage(name)
      return @stage_manager.stage_get(name)
    end

    sig { returns(T::Boolean) }
    def do_restore_datastore
      do_option
      restore_file = nil
      restore_file_arr = @option[:m]
      restore_file = restore_file_arr[0] if restore_file_arr
      new = @option[:n]
      if new
        ldump "New option is specified. DataStore restore is skipped"
        return false
      end

      if restore_file
        ldump "restoring database from #{restore_file}"
        load_store(restore_file)
        return true
      end

      return false
    rescue => e
      application_error "Exception while loading file #{restore_file}. => #{e.message}"
    end

    sig { params(again: T::Boolean).void }
    def do_option(again = false)
      if !ENV['SHEEP_RSPEC']
        if @did_process_option
          return unless again
        else
          @did_process_option = true
        end

        process_option
      else
       @option = {}
      end
    end

    # @api private
    #
    sig { returns(AnalyzerCoreReturn) }
    def do_analyze
      do_option
      if @option[:s]
        puts 'Skipping analyze'
        res = AnalyzerCoreReturn.new
        return res
      end

      dump(:pwarn) and return if @option[:d]

      count = 0
      is_eol = true
      ret = MatchResult::NotFound
      @file_manager.analyze do |data|
        count += 1
        ret = @stage_manager.analyze_stages(data)

        if ret == @eol_validation && MatchResult::Finish && !data.is_eol
          ldebug? and ldebug "Action called but it is not eol"
          is_eol = false
          break
        end

        if ret == MatchResult::NotFound
          ldebug? and ldebug "Expression not found."
          break
        end
      end

      res = AnalyzerCoreReturn.new
      res.result = ret.dup
      res.eol = is_eol
      res.next_command = next_command

      return res
    end

    # @api private
    #
    sig { params(file: String).returns(String) }
    def tokenize(file)
      tokenized = @tokenizer.feed_file(file)
      ldebug? and ldebug "start #{File.expand_path(file)}", :red
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

    sig { void }
    def process_option
      if !@option
        option_on
        option_parse(ARGV)
      end
      @option[:D]&.each do |item|
        if item.include?('=')
          key = item.split('=').first
          data = item.split('=').last
          @envdb[key] = data
        else
          @envdb[item] = '1'
        end
      end

      sheep_dir_path_set(@option[:I])
      sheep_include_file_filter_set(@option[:F])
      sheep_exclude_dir_path_set(@option[:E])
      sheep_outdir_set(@option[:o])
      sheep_template_dir_path_set(@option[:t])
    end
  end
end
