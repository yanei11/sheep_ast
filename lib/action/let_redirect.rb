# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module Sheep
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
    # Specified data will be iput again.  Ast stage to process the data can be specified at option
    # The Ast specifying can be done by domain or full name of Ast Stage
    #
    # Options:
    # ast_include <string>: Only speficied Ast name will be applied at redirected expression
    # ast_exclude <string>: after included Ast at ast_include, ast_exclude can specify to exclude the Ast
    # namespace   <tag>   : namespace can be added in pair[_namespace] at redircted expression
    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        key: Symbol,
        range: Range,
        options: T.any(Symbol, String, T::Boolean)
      ).void
    }
    def redirect(pair, datastore, key, range = 1..-1, **options)
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
