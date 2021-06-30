# typed: false
# frozen_string_literal:true

require 'erb'
require 'sorbet-runtime'
require 'rainbow/refinement'
require_relative '../log'
require_relative '../exception'
require_relative '../action/let_compile'

using Rainbow

module SheepAst
  # module to enable compile from a file to a file.
  module DataStoreCompile
    extend T::Sig
    extend T::Helpers
    include LetCompile

    sig {
      params(
        datastore: DataStore,
        template_file: T.nilable(String),
        options: T.untyped
      ).void
    }
    def compile_from_datastore(datastore, template_file = nil, **options)
      compile(nil, datastore, template_file, **options)
    end

    def initialize
      @_ctime = Time.new
      super
    end

    def ctime_get
      @_ctime
    end
  end
end
