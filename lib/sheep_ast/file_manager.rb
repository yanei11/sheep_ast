# typed: false
# frozen_string_literal:true

require 'set'
require_relative 'log'
require_relative 'datastore/datastore'
require_relative 'tokenizer'
require 'sorbet-runtime'

DEFAULT_SAVE_STACK_SIZE = 20

# TBD
module SheepAst
  # This object handles input of syntax element after parsing by tokenizer.
  # It holds stack of processing info and provide functionality of saving data and resume data
  #
  # @api private
  #
  class FileManager #rubocop: disable all
    extend T::Sig
    include Exception
    include Log

    sig { returns(T::Set[String]) }
    attr_accessor :processed_file_list

    sig { returns(String) }
    attr_accessor :last_word_check

    sig { params(stage_manager: StageManager, tokenizer: Tokenizer, datastore: DataStore).void }
    def initialize(stage_manager, tokenizer, datastore)
      super()
      @processed_file_list = Set.new
      @current_file = nil
      @file_info = FileInfo.new
      @resume_info = []
      @reg_files = []
      @scheduled_next_file = []
      @scheduled_next_chunk = []
      @analyze_data = AnalyzeData.new
      @stage_manager = stage_manager
      @tokenizer = tokenizer
      @datastore = datastore
    end

    sig { params(file: String).returns(T.nilable(T::Set[String])) }
    def processed?(file)
      ldebug? and ldebug "Mark processed => #{File.expand_path(file)}", :blue
      return @processed_file_list.add?(File.expand_path(file))
    end

    sig { returns(String) }
    def inspect
      "<#{self.class.name} object_id = #{object_id}>"
    end

    sig { params(blk: T.proc.params(arg0: AnalyzeData).void).void }
    def analyze(&blk)
      loop do
        data = next_data

        if data.expr.nil?
          linfo 'Finish analyzing.'
          break
        end

        blk.call(data)
      end
    end

    sig { returns(T.nilable(T::Array[String])) }
    def feed_line
      line = @file_info.tokenized[@file_info.line] unless @file_info.tokenized.nil?

      # line is no longer existed
      # This is the end of file.
      if line.nil?

        # strategy1: check if resume info is existed
        restored = restore_info
        if restored
          ldebug? and ldebug 'resume info is existed'
          @file_info.copy(restored)
          line = @file_info.tokenized[@file_info.line]
        else
          # strategy2: no resume info. Get next file
          if consume_file # rubocop: disable all
            ldebug? and ldebug 'Got another file'
            line = @file_info.tokenized[@file_info.line]
          else
            # Strategy3: So, nothing to process. GIve up
            ldebug? and ldebug 'Give up!!'
            line = nil
          end
        end
      end

      ldebug? and ldebug "feed line returned #{line.inspect}, line_no = #{@file_info.line}", :red
      return line
    end

    sig {
      params(line: T.nilable(T::Array[String]), rec: T::Boolean).returns(
        [T.nilable(String), T::Boolean]
      )
    }
    def feed_expr(line, rec = false) # rubocop:disable all
      expr = line[@file_info.index] unless line.nil?
      is_eol = false

      ldebug? and ldebug "feed_expr expr = #{expr.inspect}"
      ldebug? and ldebug "feed_expr file_info = #{@file_info.inspect}"

      if expr.nil?
        # strategy1: expr = nil case is two,
        # 1) line is new
        # 2) end of file
        @file_info.line += 1
        if @file_info.line < @file_info.max_line
          @file_info.index = 0
          ldebug? and ldebug 'reached to the new line. get next line.'
          expr, is_eol = feed_expr(feed_line, true)
        elsif @file_info.line == @file_info.max_line
          if @file_info.file && !@file_info.using_chunk
            # end of file
            ldebug? and ldebug 'EOF', :red
            expr = '__sheep_eof__'
          elsif @file_info.using_chunk
            # end of chunk
            ldebug? and ldebug 'EOC', :red
            expr = '__sheep_eoc__'
          end
        else
          ldebug? and ldebug 'Bug route?'
        end
      else
        @file_info.index += 1
        if T.must(line).size == @file_info.index
          is_eol = true
        else
          is_eol = false
        end
      end

      if !rec
        ldebug? and ldebug "index = #{@file_info.index} is input"
        ldebug? and ldebug "feed expr returned #{expr.inspect}, is_eol = #{is_eol.inspect}"\
          " at #{@file_info.line}:#{@file_info.index}", :red
      end

      return expr, is_eol
    end

    sig { returns(AnalyzeData) }
    def next_data
      line = feed_line
      expr, is_eol = feed_expr(line)
      @analyze_data.expr = expr
      @analyze_data.is_eol = is_eol
      @analyze_data.tokenized_line = @file_info.tokenized[@file_info.line]
      @analyze_data.tokenized_line_prev = @file_info.tokenized[@file_info.line - 1]
      @analyze_data.file_info = @file_info
      @analyze_data.file_manager = self
      @analyze_data.request_next_data = RequestNextData::Next
      @datastore.assign(:namespace_stack, @file_info.namespace_stack)
      @datastore.assign(:meta1_stack, @file_info.meta1_stack)
      @datastore.assign(:meta2_stack, @file_info.meta2_stack)
      @datastore.assign(:meta3_stack, @file_info.meta3_stack)
      if !@analyze_data.file_info.line.nil? && !@analyze_data.file_info.raw_lines.nil?
        @analyze_data.raw_line = @file_info.raw_lines[@file_info.line]
      else
        @analyze_data.raw_line = 'Not supported. Maybe it is redirected case or it is bug.'
      end
      return @analyze_data
    end

    sig { params(files: T::Array[String]).void }
    def register_files(files)
      @reg_files = files
    end

    sig { returns(T::Boolean) }
    def consume_file
      ldebug? and ldebug 'consume file called', :red
      first_time = T.let(true, T::Boolean)
      loop do
        file = @reg_files.shift
        return false if file.nil?

        ret = marc_process_main(file)
        next if !ret

        tokenized, line_count, raw_lines = @tokenizer.tokenize(file)

        # strategy: when file is empty or something,
        # the tokenized value will be nil
        # In this case, we must get new file
        next if tokenized.nil?

        # meaningful file is found. return it
        @file_info.init
        @file_info.file = file
        @file_info.raw_lines = raw_lines
        @file_info.tokenized = tokenized
        @file_info.max_line = line_count
        if first_time
          first_time = false
          @file_info.new_file_validation = true
        end
        return true
      end
    end

    sig { params(file: String).void }
    def register_next_file(file)
      reinput = marc_process_indirect(file)
      if reinput
        save_info
        @file_info.file = file
        tokenized, line_count, raw_lines = @tokenizer.tokenize(file)
        @file_info.tokenized = tokenized
        @file_info.raw_lines = raw_lines
        @file_info.max_line = line_count
      end
    end

    sig { params(chunk: T::Array[T::Array[String]]).void }
    def register_next_chunk(chunk)
      file = @file_info.file
      save_info
      @file_info.file = file
      @file_info.file = 'no file info found' if file.nil?
      @file_info.tokenized = chunk
      @file_info.using_chunk = true
      @file_info.max_line = chunk.size
    end

    sig { params(expr: String).void }
    def register_next_expr(expr)
      @file_info.init
      @tokenizer.last_word_check = @last_word_check
      @file_info.tokenized, @file_info.max_line = @tokenizer << expr
    end

    sig { void }
    def save_info
      info = FileInfo.new
      info.init
      info.copy(@file_info)
      @resume_info << info

      ldebug? and ldebug "Suspended info process!! resume_stack = #{@resume_info.length}"\
        " at info = #{info.inspect}, copied from #{@file_info.inspect}", :indianred

      # ldump "[REDIRCT] Pushed to Resume stack(#{@resume_info.length - 1}-->#{@resume_info.length})"\
      #   " at line = #{info.line.inspect}, index = #{@file_info.index.inspect}", :indianred

      @file_info.init
      threshold = ENV['SHEEP_SAVE_STACK'].nil? ? DEFAULT_SAVE_STACK_SIZE : ENV['SHEEP_SAVE_STACK']
      if @resume_info.length > threshold
        lfatal "resume stack uses more than #{threshold}. Check bug. Default = #{DEFAULT_SAVE_STACK_SIZE}."
        lfatal 'Or you can adjust environment parameter SHEEP_SAVE_STACK'
        lfatal "resume_info => #{@resume_info.inspect}"
        application_error
      end
      @stage_manager.save_info
    end

    sig { returns(T.nilable(FileInfo)) }
    def restore_info
      invoke_cb(@file_info.exit_cb, @datastore) unless @file_info.exit_cb.nil?

      info = @resume_info.pop
      ldebug? and ldebug "restore_info, info = #{info.inspect}"
      # ldump '[RESUME ] restore info from Resume stack.' unless info.nil?

      return nil if info.nil?

      @stage_manager.restore_info

      # analyze_data shall be init here
      @analyze_data.init

      ldebug? and ldebug "Resumed info process!! resume_stack = #{@resume_info.length}"\
        " for info = #{info.inspect}, for analyze_data = #{@analyze_data.inspect}", :indianred
      return info
    end

    sig { params(callback: T::Array[T.any(Symbol, String)]).void }
    def enter_cb_invoke(callback)
      invoke_cb(callback, @datastore)
    end

    sig { params(callback: T::Array[T.any(Symbol, String)], datastore: DataStore).void }
    def invoke_cb(callback, datastore)
      callback.each do |cb|
        t_cb = cb
        arg = nil
        if t_cb.is_a? String
          t_cb, arg = get_func_arg(cb)
        end
        let = Let.new
        if arg.nil?
          let.cb_action(t_cb, datastore)
        else
          let.cb_action(t_cb, datastore, arg)
        end
      end
    end

    sig { params(callback: String).returns([Symbol, T.nilable(String)]) }
    def get_func_arg(callback)
      first = callback.index('(')
      last  = callback.index(')')

      if first.nil? || last.nil? || last < first
        return callback, nil
      end

      func  = callback[0..first - 1]
      arg   = callback[first + 1..last - 1]
      return func.to_sym, arg
    end

    sig { params(namespace: T.nilable(String)).void }
    def put_namespace(namespace)
      @file_info.namespace_stack = @resume_info.last.namespace_stack.dup
      @file_info.namespace_stack << namespace
      ldebug? and ldebug "putting namespace = #{namespace.inspect}, and stack is #{@file_info.namespace_stack.inspect}"
    end

    sig { params(meta1: T.nilable(String)).void }
    def put_meta1(meta1)
      @file_info.meta1_stack = @resume_info.last.meta1_stack.dup
      @file_info.meta1_stack << meta1
      ldebug? and ldebug "putting meta1 = #{meta1.inspect}, and stack is #{@file_info.meta1_stack.inspect}"
    end

    sig { params(meta2: T.nilable(String)).void }
    def put_meta2(meta2)
      @file_info.meta2_stack = @resume_info.last.meta2_stack.dup
      @file_info.meta2_stack << meta2
      ldebug? and ldebug "putting meta2 = #{meta2.inspect}, and stack is #{@file_info.meta2_stack.inspect}"
    end

    sig { params(meta3: T.nilable(String)).void }
    def put_meta3(meta3)
      @file_info.meta3_stack = @resume_info.last.meta3_stack.dup
      @file_info.meta3_stack << meta3
      ldebug? and ldebug "putting meta3 = #{meta3.inspect}, and stack is #{@file_info.meta3_stack.inspect}"
    end

    sig { params(callback: T.nilable(T::Array[T.any(String, Symbol)])).void }
    def exit_cb_set(callback)
      @file_info.exit_cb = callback
    end

    sig {
      params(
        inc: T.nilable(
          T.any(String, T::Array[T.any(String, Regexp)])
        )
      ).void
    }
    def ast_include_set(inc)
      inc = [inc] if inc.instance_of? String
      @file_info.ast_include = inc
    end

    sig {
      params(
        exc: T.nilable(
          T.any(String, T::Array[T.any(String, Regexp)])
        )
      ).void
    }
    def ast_exclude_set(exc)
      exc = [exc] if exc.instance_of? String
      @file_info.ast_exclude = exc
    end

    sig { returns(T.nilable(T::Array[FileInfo])) }
    def resume_data
      @resume_info
    end

    sig { params(file: String).returns(T::Boolean) }
    def marc_process_main(file)
      if File.exist?(file)
        fpath = File.expand_path(file)
        db = @datastore.assign(:_sheep_processed_file_A)
        res = db&.find(fpath)
        if !res
          db.add(fpath)
          ldump "[PROCESS] #{file}", :cyan
          return true
        else
          # application_error "Same file is entried -> #{file}"
          ldump "[SKIPPED] Main given file: #{file} is already processed", :red
          return false
        end
      end
    end

    sig { params(file: String).void }
    def print_eof(file)
      t_file = file.split('/').last
      ldump "[FINISHD] #{t_file} is finished", :magenta
    end

    sig { params(file: String).returns(T.nilable(T::Boolean)) }
    def marc_process_indirect(file)
      if File.exist?(file)
        fpath = File.expand_path(file)
        db = @datastore.assign(:_sheep_processed_file_A)
        res = db&.find(fpath)
        t_file = file.split('/').last
        if !res
          db.add(fpath)
          ldump "[INCLUDE] #{t_file}", :green
          return true
        elsif process_indirect_again?
          ldump "[AGAIN] #{t_file}"
          return true
        else
          ldump "[SKIPPED] #{t_file} is already processed", :yellow
          return false
        end
      end
    end

    sig { returns(T::Boolean) }
    def process_indirect_again?
      false
    end
  end
end
