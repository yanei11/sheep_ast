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
    include Log
    include Exception

    sig { returns(AnalyzeData) }
    attr_accessor :data

    sig { returns(T::Array[String]) }
    attr_accessor :exclude_dir_path_array

    sig { returns(T::Array[String]) }
    attr_accessor :dir_path_array

    sig { returns(String) }
    attr_accessor :next_file

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

    sig {
      params(
        pair: T::Hash[Symbol, T::Array[String]],
        datastore: DataStore,
        key_id: Symbol,
        range: Range,
        options: T.untyped
      ).returns(T.nilable(T::Boolean))
    }
    def include(pair, datastore, key_id, range = 1..-2, **options)
      str = pair[key_id]
      ldebug str.inspect
      relative_path = T.must(T.must(str)[range])

      file = find_next_file(relative_path.join)
      T.must(data.file_manager).register_next_file(file) unless file.nil?
      return T.unsafe(self)._ret(**options)
    end

    private

    sig { params(file: T.nilable(String)).returns(T::Boolean) }
    def exclude_file?(file)
      return false if file.nil?

      exclude_dir_path.each do |epath|
        rp = Regexp.new("#{File.expand_path(epath)}/*")

        if !rp.match(file).nil?
          linfo "[SKIPPED]:#{file}(ex)", :yellow
          return true
        end
      end
      return false
    end

    sig { params(relative_path: String).returns(T.nilable(String)) }
    def find_next_file(relative_path)
      found_paths = []
      dir_path.each do |base|
        test_path = "#{base}/#{relative_path}"
        if File.exist?(test_path)
          ldebug "file exist: #{test_path}"
          found_paths << File.expand_path(test_path)
        end
      end

      if found_paths.count != 1
        lfatal "Duplicated include file has been found. #{found_paths.inspect}"
        application_error
      end

      file = found_paths.first
      res = exclude_file?(file) ? nil : file
      return res
    end
  end
end
