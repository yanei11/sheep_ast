# typed: false
# frozen_string_literal: true

require_relative 'action_base'
require 'rainbow/refinement'
require 'sorbet-runtime'

using Rainbow

module Sheep
  # This class is for the action to recprd the result
  class IncludeHandler < ActionBase
    extend T::Sig

    sig { returns(AnalyzeData) }
    attr_accessor :data

    sig { returns(T::Array[String]) }
    attr_accessor :exclude_dir_path_array

    sig { returns(T::Array[String]) }
    attr_accessor :dir_path_array

    sig { returns(String) }
    attr_accessor :next_file

    sig { void }
    def initialize
      super()
      @dir_path_array = []
      @exclude_dir_path_array = []
      @next_file = nil
    end

    sig { params(path: String).void }
    def register_dir_path(path)
      @dir_path_array << path
    end

    sig { params(path: String).void }
    def register_exclude_dir_path(path)
      @exclude_dir_path_array << path
    end

    sig { params(data: Symbol).returns(IncludeHandler) }
    def new(data)
      ins = super(data)
      return ins
    end

    sig { override.params(data: AnalyzeData, _node: Node).returns(MatchAction) }
    def action(data, _node)
      str = @data_store.value(store_sym)
      ldebug str.inspect
      if str.is_a? Enumerable
        str2 = str[1..-2]
        relative_path = str2.reduce(:+)
      else
        relative_path = str
      end

      file = find_next_file(relative_path)
      data.file_manager.register_next_file(file) unless file.nil?
      return MatchAction::Next
    end

    private

    sig { params(file: String).returns(T::Boolean) }
    def exclude_file?(file)
      top.exclude_dir_path_array.each do |epath|
        rp = Regexp.new(File.expand_path(epath) + '/*')

        if !rp.match(file).nil?
          linfo "[SKIPPED]:#{file}(ex)".yellow
          return true
        end
      end
      return false
    end

    sig { params(relative_path: String).returns(String) }
    def find_next_file(relative_path)
      found_paths = []
      top.dir_path_array.each do |base|
        test_path = base + '/' + relative_path
        if File.exist?(test_path)
          ldebug "file exist: #{test_path}"
          found_paths << File.expand_path(test_path)
        end
      end

      if paths.count != 1
        lfatal "Duplicated include file has been\
                  found. #{paths.inspect.yellow.underline}"
        application_error
      end

      file = found_paths.first
      file = nil if exclude_file?(file)
      return file
    end
  end
end
