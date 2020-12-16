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
        key: Symbol,
        range: Range,
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def redirect(pair, datastore, key, range = 1..-2, **options)
      chunk = nil
      line_from_en  = options[:redirect_line_from]
      line_to_en  = options[:redirect_line_to]

      line_matched = options[:redirect_line_matched]

      if line_matched
        data = pair[:_data]
        start_match = get_first_match(data)
        end_match = get_last_match(data)
        start_line = start_match.start_line
        end_line = end_match.end_line
        lprint "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
        range = start_line..end_line
        chunk = data.file_info&.tokenized[range]
      elsif line_from_en && line_to_en
        data = pair[:_data]
        start_match = get_match(data, line_from_en)
        end_match = get_match(data, line_to_en)
        start_line = start_match.start_line
        end_line = end_match.end_line
        lprint "redirecting whole line start from #{start_line.inspect} to #{end_line.inspect}"
        range = start_line..end_line
        chunk = data.file_info&.tokenized[range]
      else
        chunk = pair[key]
        application_error 'specified key did not hit' if chunk.nil?

        chunk2 = chunk[range]
        application_error 'cannot redirect exp for no Array' unless chunk2.instance_of?(Array)

        ldebug "received expr = #{chunk.inspect}, pair = #{pair.inspect}, key = #{key.inspect}", :blue
        ldebug "redirect expr = #{chunk2.inspect}", :blue
        ldebug "options = #{options.inspect}", :blue

        ns_t = options[:namespace]

        if ns_t.instance_of? Symbol
          ns_t = pair[ns_t]
          if ns_t.nil?
            lfatal "namespace symbol cannot be found in the given data => #{pair.inspect}"
            apprecation_error
          end
        end

        ldebug "namespace is #{ns_t.inspect}", :blue
      end

      if options[:dry_run]
        lprint "To be redirect : #{chunk}"
        return
      end

      save_req = SaveRequest.new(
        chunk: chunk2,
        ast_include: options[:ast_include],
        ast_exclude: options[:ast_exclude],
        namespace: ns_t
      )

      @data.save_request = save_req
    end
  end
end
