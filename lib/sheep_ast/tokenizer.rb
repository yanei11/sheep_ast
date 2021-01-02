# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

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

    sig { void }
    def initialize
      @tokenize_stage = []
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
        T.proc.params(arg0: T::Array[T.any(String, Regexp)],
                      arg1: Integer).returns([T::Array[T.any(String, Regexp)], T::Boolean])
      )
    }
    def cmp(*args)
      lambda { |array, num|
        res = T.let(true, T::Boolean)
        if !array.nil?
          args.each_with_index do |elem, idx|
            t_res = array[num + idx] == elem if elem.instance_of? String
            t_res = array[num + idx] =~ elem if elem.instance_of? Regexp
            res = false if t_res.nil? || !t_res
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
        options: T::Boolean
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
      File.open(fpath) do |f|
        f.each_line do |line|
          line_count += 1
          file_buf.push(shaping(scan(line)))
          raw_buf << line
        end
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
      @tokenize_stage.each_with_index do |blk, idx|
        args, _, options, token = blk.call(nil, 0)
        token = args.join if !token
        dump_part(idx, args, token, options, logf)
        logf.call('        |_______|') if options[:recursive]
      end
      logf.call('')
    end

    # @api private
    def dump_part(idx, args, token, options, logf)
      logf.call("stage#{idx + 1} :___\\ #{args.inspect.yellow} is combined to "\
                "#{token.inspect.red} with options = #{options.inspect}")
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
    sig { params(par: T.untyped).void }
    def token_rule(*par)
      if block_given?
        add_token T.unsafe(self).cmb(*par), yield
      else
        add_token T.unsafe(self).cmb(*par)
      end
    end

    private

    sig { params(line: String).returns(T::Array[String]) }
    def scan(line)
      if @split.nil?
        test = line.scan(/\w+|\W/)
      else
        test = line.split(@split.call)
      end

      test.reject!(&:empty?)
      if test.respond_to? :each
        # no process
      elsif test.nil?
        test = []
      else
        test = [test]
      end
      return test
    end

    # TBD
    sig { params(line: T::Array[String]).returns(T::Array[String]) }
    def shaping(line)
      buf = line

      ldebug2 "#{line} will be combined process"

      prev = T.let(nil, T.nilable(T::Array[String]))
      @tokenize_stage.each do |blk|
        loop do
          buf, options = basic_shaping(buf, blk)
          if T.must(options)[:recursive]
            ldebug 'recursiv option enable'
            ldebug "buf  => #{buf.inspect}"
            ldebug "prev => #{prev.inspect}"
            if buf != prev
              prev = buf.dup
            else
              prev = nil
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
        )
      ).returns([T::Array[String], T.nilable(T::Hash[Symbol, T::Boolean])])
    }
    def basic_shaping(line, blk)
      num = 0
      ret_array = []
      options = T.let(nil, T.nilable(T::Hash[Symbol, T::Boolean]))
      while num <= (line.size - 1)
        inc_count = 1
        store_str = line[num]
        inc_count, store_str, options = basic_shaping_part(blk, line, num)
        num += inc_count
        ret_array << store_str
      end
      return ret_array, options
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

      if inc_count.nil?
        inc_count = 1
      end

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
