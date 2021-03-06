# typed: ignore
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require 'sorbet-runtime'

module SheepAst
  # Handle tokenie process.
  #
  # @api private
  #
  # rubocop: disable all
  class Tokenizer
    extend T::Sig
    include Exception
    include Log

    sig { returns(String) }
    attr_accessor :last_word_check

    sig { void }
    def initialize
      @tokenize_stage = []
      @l_str = []
      @r_str = []
      super()
    end

    # Compare and combine expression to token
    #
    # @api private
    #
    # @deprecated
    #
    sig {
      params(
        args: T.any(String, Regexp)
      ).returns(
        T.proc.params(arg0: T.nilable(T::Array[T.any(String, Regexp)]),
                      arg1: Integer).returns([T::Array[T.any(String, Regexp)], T::Boolean])
      )
    }
    def cmp(*args)
      lambda { |array, num|
        res = T.let(true, T::Boolean)
        if !array.nil?
          size = array.size - 1
          args.each_with_index do |elem, idx|
            if num + idx == size && array[num + idx] == "\n"
              res = false
            else
              t_res = array[num + idx] == elem if elem.instance_of? String
              t_res = array[num + idx] =~ elem if elem.instance_of? Regexp
              if t_res.nil? || !t_res
                res = false
              end
            end

            break if !res
          end
        else
          res = false
        end
        [args, res]
      }
    end

    # TBD
    #
    # @api private
    #
    sig {
      params(
        blk: T.proc.params(
          arg0: T::Array[String],
          arg1: Integer
        ).returns(
          [T::Array[T.any(String, Regexp)], T.any(TrueClass, FalseClass, String), T::Hash[Symbol, T::Boolean]]
        )
      ).void
    }
    def add(&blk)
      @tokenize_stage << blk
    end

    # TBD
    #
    # @api private
    #
    # rubocop: disable all
    sig {
      params(
        blk: T.proc.params(
          arg0: T::Array[T.nilable String],
          arg1: Integer
        ).returns(
          [T::Array[T.any(String, Regexp)], T::Boolean]
        ),
        token: T.nilable(String),
        options: T.untyped
      ).void
    }
    def add_token(blk, token = nil, **options) 
      add { |line, num|
        args, t_token = blk.call(line, num)
        t_token = token if !token.nil? && t_token
        [args, t_token, options, token]
      }
    end

    # Give the split rule for the given strings.
    # Currently assuming to be used with split_space_only.
    #
    # Given that tokenizer got input as 'Hello, sheep_ast world', then 
    # With usine default separator. it returns
    #
    # ```
    # [["Hello", ",", " ", "world", ".", " ", "Now", " ", "2020", "/", "12", "/", "14", " ", "1", ":", "43"]]
    # ```
    #
    # With  use_split_rule, it returns
    #
    # ```
    # [["Hello,", "world.", "Now", "2020/12/14", "1:43"]]
    # ```
    # 
    # So, split base tokenizer is more simple than default base tokenizer.
    # But default base tokenizer has more fine-grain control.
    #
    # @example
    #   core.config_tok do |tok|
    #     tok.use_split_rule { tok.split_space_only }
    #   end
    #
    # @api public
    #
    def use_split_rule(&blk)
      @split = blk
    end

    # @api private
    sig { params(fpath: String).returns([T::Array[T::Array[String]], Integer, T::Array[String]]) }
    def tokenize(fpath)
      line_count = 0
      file_buf = []
      raw_buf = []

      if !File.exist?(fpath)
        application_error "#{fpath} is not found"
      end

      File.open(fpath) do |f|
        f.each_line do |line|
          line_count += 1
          file_buf.push(shaping(scan(line)))
          raw_buf << line
        end
      end

      if file_buf[-1][-2] != "\n"
        file_buf[-1].delete_at(-1)
      end

      return file_buf, line_count, raw_buf
    end

    # @api private
    sig { params(expr: String).returns([T::Array[T::Array[String]], Integer]) }
    def tokenize_expr(expr)
      line_count = 0
      file_buf = []
      expr.each_line do |line|
        line_count += 1
        file_buf.push(shaping(scan(line)))
      end

      if file_buf[-1][-2] != "\n"
        file_buf[-1].delete_at(-1)
      end

      return file_buf, line_count
    end

    # @api private
    sig { params(expr: String).returns([T::Array[T::Array[String]], Integer]) }
    def <<(expr)
      tokenize_expr(expr)
    end

    # @api private
    def dump(logs)
      logf = method(logs)
      logf.call('')
      logf.call('## Tokenizer information start ##')
      logf.call 'concat enclosed string like following :'
      @l_str.each_with_index do |_, index|
        logf.call " - [..., #{@l_str[index]}, a, b, c, #{@r_str[index]}, ...] => [..., #{@l_str[index]}abc#{@r_str[index]}, ...]", :cyan
      end
      logf.call('')

      logf.call 'tokenized expressions as following order :'
      @tokenize_stage.each_with_index do |blk, idx|
        args, _, options, token = blk.call(nil, 0)
        token = args.join if !token
        dump_part(idx, args, token, options, logf)
        logf.call ''
      end

    end

    # @api private
    def dump_part(idx, args, token, options, logf)
      logf.call "stage#{idx + 1}"
      logf.call " - #{args.inspect} is combined to #{token.inspect}", :cyan
      logf.call(' - This is recursively evaluated', :cyan) if options[:recursive]
    end

    # To specify split rule as space only.
    # Please note that split rule like ' ' is not suitable to use space as split rule.
    # It drops "\n" and it is an issue. Assuming to be used with use_split_rule
    #
    # @example
    #   core.config_tok do |tok|
    #     tok.use_split_rule { tok.split_space_only }
    #   end
    #
    # @api public
    #
    sig { returns Regexp }
    def split_space_only
      / |([\t\r\n\f])/
    end

    # Specify tokenizer to cobine the expression or convert to given string
    #
    # @example
    #   core.config_tok do |tok|
    #     tok.use_split_rule { tok.split_space_only }
    #     tok.token_rule('show', 'isis', 'neighbor') { 'show isis neighbor' }
    #     tok.token_rule('show', 'isis', 'database') { 'show isis database' }
    #   end
    #
    # @api public
    #
    sig { params(par: T.untyped, kwargs: T.untyped).void }
    def token_rule(*par, **kwargs)
      if block_given?
        T.unsafe(self).add_token(T.unsafe(self).cmb(*par), yield, **kwargs)
      else
        T.unsafe(self).add_token(T.unsafe(self).cmb(*par), **kwargs)
      end
    end

    sig { params(l_str: String, r_str: String, options: T.untyped).void }
    def concat_inline(l_str, r_str, **options)
      @concat_enclosed = true
      @l_str << l_str
      @r_str << r_str
      @drop_closure = options[:drop_closure]
    end

    private

    sig { params(line: String).returns(T::Array[String]) }
    def scan(line)
      ldebug? and ldebug "scan line = #{line.inspect}"
      if @split.nil?
        test = T.must(line).scan(/\w+|\W/)
      else
        test = T.must(line).split(@split.call)
      end

      test << '__sheep_eol__' unless test.nil?

      if @concat_enclosed
        @l_str.each_with_index do |_, index|
          test = concat_enclosed(test, @l_str[index], @r_str[index])
        end
      end

      if !@last_word_check.nil?
        if @last_word_check != line[-1]
          ldebug? and ldebug "last_word_check failed; drop last word"
          test = test[0..-2]
        end
      end

      T.must(test).reject!(&:empty?)
      if test.respond_to? :each
        # no process
      elsif test.nil?
        test = []
      else
        test = [test]
      end

      return T.unsafe(test)
    end

    sig { params(line_array: T::Array[String], l_str: String, r_str: String).returns(T::Array[String]) }
    def concat_enclosed(line_array, l_str, r_str)
      new_array = line_array
      loop do
        test = new_array.dup
        new_array = concat_enclosed_part(new_array, l_str, r_str)
        break if test == new_array
      end

      return new_array
    end

    sig { params(line_array: T::Array[String], l_str: String, r_str: String).returns(T::Array[String]) }
    def concat_enclosed_part(line_array, l_str, r_str)
      first_index = line_array.index(l_str)
      return line_array if first_index.nil?

      last_index = line_array[first_index + 1..-1].index(r_str)
      return line_array if last_index.nil?


      drop = @drop_closure
      if drop
        if last_index == 0
          # In this case, it means there are no enclosed elements.
          # This is special case
          drop = false
        end
      end

      if drop
        new_array = line_array[0..first_index - 1] +
          [line_array[(first_index + 1)..(first_index + last_index)].join] +
          line_array[(first_index + last_index + 2)..-1]
      else
        new_array = line_array[0..first_index - 1] +
          [line_array[(first_index)..(first_index + last_index + 1)].join] +
          line_array[(first_index + last_index + 2)..-1]
      end

      return new_array
    end

    # TBD
    sig { params(line: T::Array[String]).returns(T::Array[String]) }
    def shaping(line)
      buf = line

      ldebug? and ldebug2 "#{line} will be combined process"

      # prev = T.let(nil, T.nilable(T::Array[String]))
      @tokenize_stage.each do |blk|
        args, _, options, token = blk.call(nil, 0)
        recursive = true if options[:recursive]

        loop do
          buf, _, changed = basic_shaping(buf, blk, recursive)
          if recursive
            if !changed
              break
            end
          else
            break
          end
        end
      end
      buf = [] if buf.nil?
      return buf
    end

    sig {
      params(
        line: T::Array[String],
        blk: T.proc.params(arg0: T::Array[String], arg1: Integer).returns(
          T.any(NilClass, [Integer, T.any(String, T::Array[String]),
                           T.nilable(T::Hash[Symbol, T::Boolean])])
        ),
        recursive: T.nilable(T::Boolean)
      ).returns([T::Array[String], T.nilable(T::Hash[Symbol, T::Boolean]), T::Boolean])
    }
    def basic_shaping(line, blk, recursive)
      num = 0
      ret_array = []
      options = T.let(nil, T.nilable(T::Hash[Symbol, T::Boolean]))
      changed = T.let(false, T::Boolean)
      while num <= (line.size - 1)
        inc_count = 1
        store_str = line[num]
        if !recursive || !changed
          inc_count, store_str, options = basic_shaping_part(blk, line, num)
        end

        if inc_count != 1
          changed = true
        end

        num += inc_count
        ret_array << store_str
      end
      return ret_array, options, changed
    end

    sig {
      params(
        blk: T.proc.params(arg0: T::Array[String], arg1: Integer).returns(
          T.any(NilClass, [Integer, T.any(String, T::Array[String]),
                           T.nilable(T::Hash[Symbol, T::Boolean])])
        ),
        line: T::Array[String],
        num: Integer
      ).returns([Integer, String, T.nilable(T::Hash[Symbol, T::Boolean])])
    }
    def basic_shaping_part(blk, line, num)
      args, store_str, options = blk.call(line, num)
      inc_count = T.must(args).size
      changed = false

      if inc_count.nil?
        inc_count = 1
      end

      # In this route, store_str = false
      # So, it shows token is ended or not started
      if !store_str
        inc_count = 1
        store_str = line[num]
      end

      if !store_str.is_a? String
        index1 = num
        index2 = num + T.must(inc_count) - 1
        store_str = T.must(line[index1..index2]).join
      end

      return inc_count, store_str, options
    end

    alias cmb cmp
  end
end
