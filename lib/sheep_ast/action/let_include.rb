# typed: true
# frozen_string_literal: true

require 'rainbow/refinement'
require 'sorbet-runtime'
require_relative '../log'
require_relative '../exception'

module SheepAst
  # This class is for the action to recprd the result
  module LetInclude
    extend T::Sig
    include Kernel
    include LetHelper
    include Log
    include Exception

    sig { returns(T::Array[String]) }
    def dir_path
      val = @data_store.value(:_sheep_dir_path)
      return val.nil? ? [] : val
    end

    sig { returns(T::Array[String]) }
    def exclude_dir_path
      val = @data_store.value(:_sheep_exclude_dir_path)
      return val.nil? ? [] : val
    end

    # Handle analysis target including another file
    #
    # @example
    #   A(:let, [:include, key_id, [Range], [options]])
    #
    # redirect specified data to specified Ast. The data can be specified by tag and by specified range.
    # Specified data will be iput again.  Ast stage to process the data can be specified at option.
    # The Ast specifying can be done by domain or full name of Ast Stage.
    #
    # @option options [String] :ast_include Only speficied Ast name will be applied at redirected expression.
    # @option options [String] :ast_exclude after included Ast at ast_include, this specify to exclude the Ast
    sig {
      params(
        pair: T::Hash[Symbol, T.untyped],
        datastore: DataStore,
        key_id: Symbol,
        range: Range,
        options: T.untyped
      ).returns(T.nilable(T::Boolean))
    }
    def include(pair, datastore, key_id, range = 1..-2, **options)
      str = pair[key_id]
      relative_path = T.must(T.must(str)[range]).join
      ldebug? and ldebug "let include is called with #{relative_path.inspect}"

      file = find_next_file(relative_path)

      if !file.nil?
        save_req = SaveRequest.new(
          file: file,
          ast_include: options[:ast_include],
          ast_exclude: options[:ast_exclude],
          namespace: nil
        )
        @data.save_request = save_req
      end

      return T.unsafe(self).ret(**options)
    end

    private

    sig { params(file: T.nilable(String)).returns(T::Boolean) }
    def exclude_file?(file)
      return false if file.nil?

      exclude_dir_path.each do |epath|
        rp = Regexp.new("#{File.expand_path(epath)}/*")

        if !rp.match(file).nil? # rubocop:disable all
          t_file = file.split('/').last
          ldump "[EXCLUDE] #{t_file}", :yellow
          return true
        end
      end
      return false
    end

    sig { params(relative_path: String).returns(T.nilable(String)) }
    def find_next_file(relative_path)
      file = find_file(dir_path, relative_path)
      if file.nil?
        ldump "[NOT FOUND] #{relative_path}", :red
      end

      res = exclude_file?(file) ? nil : file
      return res
    end
  end
end
