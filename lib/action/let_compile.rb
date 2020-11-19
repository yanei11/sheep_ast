# typed: true
# frozen_string_literal:true

require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module Sheep
  # TBD
  module LetCompile
    extend T::Sig
    extend T::Helpers
    def compile(pair, datastore, template_file, to_file); end
  end
end
