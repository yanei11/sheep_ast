# typed:true
# frozen_string_literal:true

require_relative 'log'
require_relative 'exception'
require 'sorbet-runtime'

module SheepAst
  # TBD
  class Tokenizer # rubocop: disable all
    extend T::Sig
    include Exception
    include Log

    sig { void }
    def initialize
      @tokenize_stage = []
      super()
    end

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
    def add_token(blk, token = nil, **options)  # rubocop: disable all
      add { |line, num|
        args, t_token = blk.call(line, num)
        t_token = token if !token.nil? && t_token
        [args, t_token, options]
      }
    end

    def use_split_rule(&blk)
      @split = blk
    end

    # TBD
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

    sig { params(expr: String).returns([T::Array[T::Array[String]], Integer]) }
    def <<(expr)
      tokenize_expr(expr)
    end

    def dump(logs)
      logf = method(logs)
      @tokenize_stage.each_with_index do |blk, idx|
        args, _a, options = blk.call(nil, 0)
        if options[:recursive]
          logf.call("stage#{idx + 1} : ___\\  #{args.inspect}, #{options.inspect}")
          logf.call('        |_______|')
        else
          logf.call("stage#{idx + 1} : #{args.inspect}, #{options.inspect}")
        end
      end
    end

    private

    sig { params(line: String).returns(T::Array[String]) }
    def scan(line)
      if @split.nil?
        test = line.scan(/\w+|\W/)
      else
        test = line.split(@split.call)
        # split erase "\n" so added here
        test << "\n"
      end
      if test.respond_to? :each
        # no process
      elsif test.nil?
        test = []
      else
        test = [test]
      end
      T.cast(test, T::Array[String])
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
