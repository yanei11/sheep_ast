# typed: false
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module Sheep
  # TBD
  module LetRedirect
    extend T::Sig
    extend T::Helpers
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
