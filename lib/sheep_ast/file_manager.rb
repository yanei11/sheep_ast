# typed: false
# frozen_string_literal:true

require 'set'
require_relative 'log'
require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

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

    sig { params(stage_manager: StageManager, tokenizer: Tokenizer).void }
    def initialize(stage_manager, tokenizer)
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
    end

    sig { params(file: String).returns(T.nilable(T::Set[String])) }
    def processed?(file)
      ldebug "Mark processed => #{File.expand_path(file)}".blue
      return @processed_file_list.add?(File.expand_path(file))
    end

    sig { returns(String) }
    def inspect
      "<#{self.class.name} object_id = #{object_id}>"
    end

    sig { params(blk: T.proc.params(arg0: AnalyzeData).void).void }
    def analyze(&blk)
      reinput_req = false
      loop do
        data = nil
        if reinput_req
          reinput_req = false
          data = @prev_data
          data.request_next_data = RequestNextData::Next
          ldebug "received RequestData::Again. reinput data = #{data.inspect}"
        else
          data = next_data
          @prev_data = data.dup
        end

        if data&.expr.nil?
          linfo 'Finish analyzing.'
          break
        end

        blk.call(data)

        if data&.request_next_data == RequestNextData::Again
          reinput_req = true
          ldebug 'reinput_req'
        end
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
          ldebug 'resume info is existed'
          @file_info.copy(restored)
          line = @file_info.tokenized[@file_info.line]
        else
          # strategy2: no resume info. Get next file
          if consume_file # rubocop: disable all
            ldebug 'Got another file'
            line = @file_info.tokenized[@file_info.line]
          else
            # Strategy3: So, nothing to process. GIve up
            ldebug 'Give up!!'
            line = nil
          end
        end
      end

      ldebug "feed line returned #{line.inspect}, line_no = #{@file_info.line}".red
      return line
    end

    sig { params(line: T.nilable(T::Array[String]), rec: T::Boolean).returns(T.nilable(String)) }
    def feed_expr(line, rec = false) # rubocop:disable all
      expr = line[@file_info.index] unless line.nil?
      # expr = '__sheep_newline__' if expr == "\n"

      ldebug "feed_expr expr = #{expr.inspect}"
      ldebug "feed_expr file_info = #{@file_info.inspect}"

      if expr.nil?
        # strategy1: expr = nil case is two,
        # 1) line is new
        # 2) end of file
        @file_info.line += 1
        if @file_info.line < @file_info.max_line
          @file_info.index = 0
          ldebug 'reached to the new line. get next line.'
          expr = feed_expr(feed_line, true)
        elsif @file_info.line == @file_info.max_line
          if !@file_info.file.nil?
            ldebug 'EOF'.red
            expr = '__sheep_eof__'
            # else
            # ldebug 'EOC'.red
            # expr = '__sheep_eoc__'
          end
        else
          ldebug 'Bug route?'
        end
      else
        @file_info.index += 1
      end

      if !rec
        ldebug "index = #{@file_info.index} is input"
        ldebug "feed expr returned #{expr.inspect} at #{@file_info.line}:#{@file_info.index}".red
      end

      return expr
    end

    sig { returns(AnalyzeData) }
    def next_data
      line = feed_line
      expr = feed_expr(line)
      @analyze_data.expr = expr
      @analyze_data.tokenized_line = line
      @analyze_data.file_info = @file_info
      @analyze_data.file_manager = self
      @analyze_data.request_next_data = RequestNextData::Next
      if !@analyze_data.file_info.line.nil? && !@analyze_data.file_info.raw_lines.nil?
        @analyze_data.raw_line = @analyze_data.file_info.raw_lines[@analyze_data.file_info.line]
      end
      return @analyze_data
    end

    sig { params(files: T::Array[String]).void }
    def register_files(files)
      @reg_files = files
    end

    sig { returns(T::Boolean) }
    def consume_file
      ldebug 'consume file called'.red
      first_time = true
      loop do
        file = @reg_files.shift
        return false if file.nil?

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

    sig { params(file: T::Array[String]).void }
    def register_next_file(file)
      save_info
      @file_info.file = file
      @file_info.tokenized = @tokenizer.tokenize(file)
    end

    sig { params(chunk: T::Array[T::Array[String]]).void }
    def register_next_chunk(chunk)
      file = @file_info.file
      save_info
      @file_info.file = file
      @file_info.file = 'no file info found' if file.nil?
      @file_info.tokenized = chunk
      @file_info.max_line = chunk.size
    end

    sig { params(expr: String).void }
    def register_next_expr(expr)
      @file_info.init
      @file_info.tokenized, @file_info.max_line = @tokenizer << expr
    end

    sig { void }
    def save_info
      info = FileInfo.new
      info.init
      info.copy(@file_info)
      @resume_info << info

      ldebug "Suspended info process!! resume_stack = #{@resume_info.length}"\
        " for info = #{info.inspect}, copied from #{@file_info.inspect}".color(:indianred)

      @file_info.init
      threshold = ENV['SHEEP_SAVE_STACK'].nil? ? 10 : ENV['SHEEP_SAVE_STACK']
      if @resume_info.length > threshold
        lfatal "resume stack uses more than #{threshold}. Check bug. Default = 10."
        lfatal 'Or you can adjust environment parameter SHEEP_SAVE_STACK'
        lfatal "resume_info => #{@resume_info.inspect}"
        application_error
      end
      @stage_manager.save_info
    end

    sig { returns(T.nilable(FileInfo)) }
    def restore_info
      info = @resume_info.pop
      ldebug "restore_info, info = #{info.inspect}"
      return nil if info.nil?

      @stage_manager.restore_info

      # analyze_data shall be init here
      @analyze_data.init

      ldebug "Resumed info process!! resume_stack = #{@resume_info.length}"\
        " for info = #{info.inspect}, for analyze_data = #{@analyze_data.inspect}".color(:indianred)
      return info
    end

    sig { params(namespace: T.nilable(String)).void }
    def put_namespace(namespace)
      @file_info.namespace_stack = @resume_info.last.namespace_stack.dup
      @file_info.namespace_stack << namespace
      ldebug "putting namespace = #{namespace.inspect}, and stack is #{@file_info.namespace_stack.inspect}"
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
  end
end
