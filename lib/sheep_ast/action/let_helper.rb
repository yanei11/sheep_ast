# typed: true
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'
require_relative '../log'
require_relative '../exception'

using Rainbow

module SheepAst
  # Let included module. Utility functions to be used inside of Let
  #
  # @api private
  #
  # rubocop:disable all
  module LetHelper
    extend T::Sig
    extend T::Helpers
    include Log
    include Exception

    def initialize
      super()
    end

    def get_first_match(data)
      missing_impl
    end

    def get_last_match(data)
      missing_impl
    end

    def get_match(data, num)
      missing_impl
    end

    sig {
      params(dirs: T.nilable(T::Array[String]), relative_path: T.nilable(String)).returns(
        T.nilable(String))
    }
    def find_file(dirs, relative_path)
      return nil if relative_path.nil?
      return relative_path if dirs.nil?

      found_paths = []
      dirs.each do |base|
        test_path = "#{base}/#{relative_path}"
        if File.exist?(test_path)
          ldebug? and ldebug "file exist: #{test_path}"
          found_paths << File.expand_path(test_path)
        end
      end

      if found_paths.count > 1
        lfatal "Duplicated include file has been found. #{found_paths.inspect}"
        application_error
      end

      return found_paths.first
    end

    sig {
      params(
        file: String,
        res: String,
        options: T.untyped
      ).void
    }
    def update_file(file, res, **options)
      if File.exist?(file)
        ftime = File.ctime(file)
        test = ctime_get <=> ftime
        case test
        when 1
          ldebug? and ldebug "#{file} is created before application launch. Delete it first!"
          File.delete(file)
        when -1
          # lprint "#{file} is created after factory created. Nothing to do."
        else
          lfatal "Unexpected timestamp info. #{ctime_get}, "\
            "file = #{file}, ftime = #{ftime}, test = #{test.inspect}"
          application_error
        end
      end

      mode = options[:mode]
      perm = options[:perm]
      mode = 'a' if mode.nil?
      if perm.nil?
        File.open(file, mode) { |f|
          f.write(res)
        }
      else
        File.open(file, mode, perm) { |f|
          f.write(res)
        }
      end

      ldump "file is generated to #{file}, by mode: #{mode}, perm: #{perm}"
    end

    def ctime_get; end

    # Extract line from first matched line to last matched line
    #
    # @note This is used inside :redirect function
    #
    sig { params(data: AnalyzeData).returns(T.nilable(T::Array[T::Array[String]])) }
    def line_matched(data)
      start_match = get_first_match(data)
      end_match = get_last_match(data)
      start_line = start_match.start_line
      end_line = end_match.end_line
      ldebug? and ldebug "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
      range = start_line..end_line
      return data.file_info&.tokenized&.[](range)
    end

    # Extract line from given matched line to given matched line
    #
    # @note This is used inside :redirect function
    #
    sig {
      params(
        data: AnalyzeData,
        key: Symbol,
        line_from: Integer,
        line_to: Integer,
        trim: T.nilable(Range)
      ).returns(
        T.nilable(T::Array[T::Array[String]])
      )
    }
    def line_from_to(data, key, line_from, line_to, trim = nil)
      baseline_match = get_match(data, key)
      baseline = baseline_match.start_line
      start_line = baseline + line_from
      end_line = baseline + line_to
      if start_line < 0 || end_line > data.file_info&.max_line
        lfatal "start_line = #{start_line}, end_line = #{end_line}, max_line = #{data.file_info&.max_line}"
        application_error 'start_line < 0 or end_line > max_line'
      end
      ldebug? and ldebug "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
      range = start_line..end_line
      return data.file_info&.tokenized&.[](range)
    end

    # Data specified key is extracted and range is applied to it.
    # After that, regenerating newline with data_shaping function.
    #
    # @note This is used inside :redirect function
    #
    sig {
      params(
        key: Symbol,
        pair: T::Hash[Symbol, T::Array[String]],
        range: Range,
        options: T.untyped
      ).returns(T::Array[T::Array[String]])
    }
    def line_enclosed(key, pair, range, **options)
      chunk = pair[key]
      data = pair[:_data]
      baseline_match = get_match(data, key)
      baseline = baseline_match.start_line
      # binding.pry
      if chunk.nil?
        str = "specified key did not hit. data = #{pair.inspect}, key = #{key}"
        application_error str
      end

      chunk = T.must(chunk)[range]
      application_error 'cannot redirect exp for no Array' unless chunk.instance_of?(Array)

      chunk = T.unsafe(self).data_shaping(chunk, **options)
      return chunk
    end

    # Getting namespace
    sig {
      params(
        pair: T::Hash[Symbol, String],
        name: T.nilable(T.any(Symbol, String))
      ).returns(T.nilable(String))
    }
    def ns_get(pair, name)
      return nil if name.nil?

      if name.instance_of? Symbol
        ns_t = pair[T.cast(name, Symbol)]
        if ns_t.nil?
          lfatal "namespace symbol cannot be found in the given data => #{pair.inspect}"
          application_error
        end
      end

      ldebug? and ldebug "namespace is #{ns_t.inspect}", :blue
      return ns_t
    end

    # Regenerating newline from the raw data
    sig {
      params(
        chunk: T::Array[T::Array[String]],
        options: T.untyped
      ).returns(
        T.any(T::Array[String], T::Array[T::Array[String]])
      )
    }
    def data_shaping(chunk, **options)
      if options[:raw]
        [chunk]
      else
        chunk.slice_after("\n").to_a
      end
    end

    sig { void }
    def format_dump
      ldump ''
      ldump '--- show ---'
      yield
      ldump '--- end  ---'
      ldump ''
    end

    sig {
      params(
        pair: T::Hash[Symbol, T.untyped],
        options: T.untyped
      ).returns(String)
    }
    def w_or_wo_ns(pair, **options)
      t_ns = ''
      namespace_separator = ''
      if options[:namespace_key] || options[:namespace_value] || options[:namespace]
        namespace_separator = T.unsafe(self).namespace_separator(**options)
        namespace = pair[:_namespace]
        namespace.reverse_each do |elem|
          t_ns = "#{elem}#{namespace_separator}#{t_ns}"
        end
      end
      ns = t_ns.dup
      (1..namespace_separator.length).each do
        ns.chop!
      end
      return ns
    end

    def namespace_separator(**options)
      namespace_sep = options[:namespace_separator]
      namespace_sep = '::' if namespace_sep.nil?
      return namespace_sep
    end

    def namespace_separator_file(**options)
      namespace_sep = options[:namespace_separator_file]
      namespace_sep = '::' if namespace_sep.nil?
      return namespace_sep
    end
  end
end
