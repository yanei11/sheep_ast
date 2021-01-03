# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module SheepAst
  # Let included module. Utility functions to be used inside of Let
  #
  # @api private
  #
  module LetHelper
    extend T::Sig
    extend T::Helpers

    # Extract line from first matched line to last matched line
    #
    # @note This is used inside :redirect function
    #
    sig { params(data: AnalyzeData).returns(T::Array[T::Array[String]]) }
    def _line_matched(data)
      start_match = get_first_match(data)
      end_match = get_last_match(data)
      start_line = start_match.start_line
      end_line = end_match.end_line
      ldebug "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
      range = start_line..end_line
      return data.file_info&.tokenized&.[](range)
    end

    # Extract line from given matched line to given matched line
    #
    # @note This is used inside :redirect function
    #
    sig { params(data: AnalyzeData, line_from: Symbol, line_to: Symbol).returns(T::Array[T::Array[String]]) }
    def _line_from_to(data, line_from, line_to)
      start_match = get_match(data, line_from)
      end_match = get_match(data, line_to)
      start_line = start_match.start_line
      end_line = end_match.end_line
      ldebug "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
      range = start_line..end_line
      return data.file_info&.tokenized&.[](range)
    end

    # Data specified key is extracted and range is applied to it.
    # After that, regenerating newline with _data_shaping function.
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
    def _line_enclosed(key, pair, range, **options)
      chunk = pair[key]
      application_error 'specified key did not hit' if chunk.nil?

      chunk = chunk[range]
      application_error 'cannot redirect exp for no Array' unless chunk.instance_of?(Array)

      chunk = _data_shaping(chunk, options)
      return chunk
    end

    # Getting namespace
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        name: T.nilable(T.any(Symbol, String))
      ).returns(T.nilable(String))
    }
    def _ns_get(pair, name)
      return nil if name.nil?

      if name.instance_of? Symbol
        ns_t = pair[name]
        if ns_t.nil?
          lfatal "namespace symbol cannot be found in the given data => #{pair.inspect}"
          apprecation_error
        end
      end

      ldebug "namespace is #{ns_t.inspect}", :blue
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
    def _data_shaping(chunk, **options)
      if !chunk.is_a? Enumerable
        return chunk
      elsif options[:raw]
        [chunk]
      else
        chunk.slice_after("\n").to_a
      end
    end

    sig { void }
    def _format_dump
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
      ns = ''
      if options[:namespace_key] || options[:namespace_value] || options[:namespace]

        namespace = pair[:_namespace]
        namespace.reverse_each do |elem|
          ns = "#{elem}::#{ns}"
        end
      end
      return ns.chop.chop
    end
  end
end
