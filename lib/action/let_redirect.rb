# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module SheepAst
  # Let included module
  module LetRedirect
    extend T::Sig
    extend T::Helpers

    # Redirect given expression block to specified ast
    #
    # Syntax:
    # A(:let, [:redirect, :<tag; symbol to data to redirect>, <Range>, [options]])
    #
    # redirect specified data to specified Ast. The data can be specified by tag and by specified range.
    # Specified data will be iput again.  Ast stage to process the data can be specified at option.
    # The Ast specifying can be done by domain or full name of Ast Stage.
    #
    # Options:
    # - ast_include <string>: Only speficied Ast name will be applied at redirected expression.
    # - ast_exclude <string>: after included Ast at ast_include, ast_exclude can specify to exclude the Ast
    # - namespace   <tag>   : namespace can be added in pair[_namespace] at redircted expression.
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        key: T.nilable(Symbol),
        range: Range,
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def redirect(pair, datastore, key = nil, range = 1..-2, **options)
      chunk = nil
      line_from_en = options[:redirect_line_from]
      line_to_en = options[:redirect_line_to]
      line_matched = options[:redirect_line_matched]
      line_range = options[:redirect_line_range]
      data = pair[:_data]

      if line_matched
        chunk = _redirect_line_matched(data)
      elsif line_from_en && line_to_en
        chunk = _redirect_line_from_to(data)
      else
        chunk = _redirect_line_enclosed(T.must(key), pair, range)
      end
      chunk = _redirect_line_range(chunk, line_range)

      ldebug "received expr = #{chunk.inspect}, "\
        "pair = #{pair.inspect}, key = #{key.inspect}", :blue
      ldebug "options = #{options.inspect}", :blue
      ns_t = _ns_get(pair, options[:namespace])

      if options[:dry_run]
        ldump "To be redirect : #{chunk.inspect}"
        return
      end

      if options[:debug]
        ldump "To be redirect : #{chunk.inspect}"
      end

      ldebug "To be redirect : #{chunk.inspect}"

      save_req = SaveRequest.new(
        chunk: chunk,
        ast_include: options[:ast_include],
        ast_exclude: options[:ast_exclude],
        namespace: ns_t
      )

      @data.save_request = save_req
    end

    sig { params(data: AnalyzeData).returns(T::Array[T::Array[String]]) }
    def _redirect_line_matched(data)
      start_match = get_first_match(data)
      end_match = get_last_match(data)
      start_line = start_match.start_line
      end_line = end_match.end_line
      ldebug "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
      range = start_line..end_line
      return data.file_info&.tokenized&.[](range)
    end

    sig { params(data: AnalyzeData).returns(T::Array[T::Array[String]]) }
    def _redirect_line_from_to(data)
      start_match = get_match(data, line_from_en)
      end_match = get_match(data, line_to_en)
      start_line = start_match.start_line
      end_line = end_match.end_line
      ldebug "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
      range = start_line..end_line
      return data.file_info&.tokenized&.[](range)
    end

    sig {
      params(
        chunk: T::Array[T::Array[String]],
        range: T.nilable(Range)
      ).returns(
        T::Array[T::Array[String]]
      )
    }
    def _redirect_line_range(chunk, range)
      return chunk if range.nil?

      return chunk[range]
    end

    sig {
      params(
        key: Symbol,
        pair: T::Hash[Symbol, T::Array[String]],
        range: Range,
        options: T.untyped
      ).returns(T::Array[T::Array[String]])
    }
    def _redirect_line_enclosed(key, pair, range, **options)
      chunk = pair[key]
      application_error 'specified key did not hit' if chunk.nil?

      chunk = chunk[range]
      application_error 'cannot redirect exp for no Array' unless chunk.instance_of?(Array)

      chunk = data_shaping(chunk, options)
      return chunk
    end

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
  end
end
