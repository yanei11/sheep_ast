# typed: true
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'
require_relative '../log'
require_relative '../exception'
require_relative 'let_helper'

using Rainbow

module SheepAst
  # Let included module
  module LetRedirect
    extend T::Sig
    extend T::Helpers
    include Kernel
    include LetHelper
    include Log
    include Exception

    # Redirect given expression block to specified ast
    #
    # @example
    #   A(:let, [:redirect, [tag; symbol to data to redirect], [Range], [options]])
    #
    # redirect specified data to specified Ast. The data can be specified by tag and by specified range.
    # Specified data will be iput again.  Ast stage to process the data can be specified at option.
    # The Ast specifying can be done by domain or full name of Ast Stage.
    #
    # @option options [String] :ast_include Only speficied Ast name will be applied at redirected expression.
    # @option options [String] :ast_exclude after included Ast at ast_include, this specify to exclude the Ast
    # @option options [Symbol, String] :namespace is specified if String, it takes from pair if it is Symbol
    # @option options [Range] :redirect_line_from_to  It takes Range value = from..to.
    #                          redirect lines started from key + from index to key + to index.
    #                          key takes Symbol to specify which match is used to the line index.
    #                          When key is nil, it uses `:_1` default.
    # @option options [Boolean] :redirect_line_matched redirect whole line from first matched until last matched
    # @option options [Boolean] :dry_run it does not do redirect but output debug string which is to be redirected
    # @option options [Boolean] :debug it print redirected sentence
    #
    # rubocop: disable all
    sig {
      params(
        pair: T::Hash[Symbol, T.untyped],
        datastore: DataStore,
        key: T.nilable(Symbol),
        range: Range,
        options: T.untyped
      ).returns(T.nilable(T::Boolean))
    }
    def redirect(pair, datastore, key = nil, range = 1..-2, **options)
      chunk = nil
      line_matched = options[:redirect_line_matched]
      line_from_to = T.let(options[:redirect_line_from_to], T.nilable(Range))
      line_from = line_from_to&.first
      line_to = line_from_to&.last
      data = pair[:_data]

      if line_matched
        chunk = line_matched(data)
      elsif line_from_to
        key = :_1 if key.nil?
        chunk = line_from_to(data, key, line_from, line_to, nil)
      else
        chunk = line_enclosed(T.must(key), pair, range)
      end

      ldebug "received expr = #{chunk.inspect}, "\
        "pair = #{pair.inspect}, key = #{key.inspect}", :blue
      ldebug "options = #{options.inspect}", :blue
      ns_t = ns_get(pair, options[:namespace])

      if options[:dry_run]
        format_dump {
          ldump "To be redirect : #{chunk.inspect}"
          ldump "Namespace : #{ns_t}"
        }
        return T.unsafe(self).ret(**options)
      end

      if options[:debug]
        format_dump {
          ldump "To be redirect : #{chunk.inspect}"
          ldump "Namespace : #{ns_t}"
        }
      end

      ldebug "To be redirect : #{chunk.inspect}"

      save_req = SaveRequest.new(
        chunk: chunk,
        ast_include: options[:ast_include],
        ast_exclude: options[:ast_exclude],
        namespace: ns_t
      )

      @data.save_request = save_req
      return T.unsafe(self).ret(**options)
    end
  end
end
