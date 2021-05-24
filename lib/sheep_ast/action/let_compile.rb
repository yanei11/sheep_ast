# typed: false
# frozen_string_literal:true

require 'erb'
require 'sorbet-runtime'
require 'rainbow/refinement'
require_relative '../log'
require_relative '../exception'
require_relative 'let_helper'

using Rainbow

module SheepAst
  # module to enable compile from a file to a file.
  module LetCompile
    extend T::Sig
    extend T::Helpers
    include Kernel
    include LetHelper
    include Log
    include Exception

    # Generate file from the template file.
    # It uses erb library to embed variable.
    # Please use erb syntax for the template_file.
    #
    # @example
    #   A(:let, [:compile, template_file, [options]])
    #
    # The only original thing from erb syntax, to be generate file name is specified by number 1 line like:
    #
    # `<%# Output file name => !"spec/res/datastore".res!  %>`
    #
    # This geenrate file spec/res/datastore.res.
    # It can be used function for the filename like:
    #
    # `<%# Output file name => !"spec/res/#{construct_file_name(namespace, data[:_2], **options)}".res!  %>`
    #
    # The function must be defined in the let object.
    #
    # @option options [Boolean] :dry_run print variables that can be userd in the erb.
    #                            With this option, only print is printed and not generating file
    # @option options [String]  :mode Set File mode. default value is 'a'
    # @option options [Integer] :perm Set File permission. default value is 0600
    #
    # rubocop:disable all
    sig {
      params(
        data: T.nilable(T::Hash[Symbol, T.untyped]),
        datastore: DataStore,
        template_file: T.nilable(String),
        options: T.untyped
      ).void
    }
    def compile(data, datastore, template_file = nil, **options)
      if !data.nil?
        namespace = w_or_wo_ns(data, **{ **options, namespace: true })
        namespace_arr = data[:_namespace]
      end
      outdir = datastore.value(:_sheep_outdir)
      outdir = './' if outdir.nil?
      template_dir = datastore.value(:_sheep_template_dir)
      template_file_ = find_file(template_dir, template_file)

      if !template_file_.nil?
        raw = File.read(template_file_)
        head_index = raw.index("\n")
        head = raw[0..T.must(head_index) - 1]
        partitioned = T.must(T.must(head).split('!')[1]).rpartition('.')
        suffix = partitioned.last
        title = binding.eval(partitioned.first) # rubocop:disable all
      end

      user_def = T.unsafe(self).user_def_compile(data, datastore, template_file_, **options)

      if options[:dry_run]
        format_dump {
          ldump "data : #{data.inspect}"
          ldump "namespace : #{namespace.inspect}"
          ldump "namespace_arr : #{namespace_arr.inspect}"
          ldump "user_def : #{user_def.inspect}"
          ldump "erb_head : #{head}"
          ldump "title : #{title}"
          ldump "suffix : #{suffix}"
        }
      end

      ldebug? and ldebug '=== compile debug ==='
      ldebug? and ldebug "data : #{data.inspect}"
      ldebug? and ldebug "namespace : #{namespace.inspect}"
      ldebug? and ldebug "namespace_arr : #{namespace_arr.inspect}"
      ldebug? and ldebug "user_def : #{user_def.inspect}"
      ldebug? and ldebug "erb_head : #{head}"
      ldebug? and ldebug "title : #{title}"
      ldebug? and ldebug "suffix : #{suffix}"
      ldebug? and ldebug "outdir : #{outdir.inspect}"
      ldebug? and ldebug '=== end ==='

      template_contents = T.must(raw)[T.must(head_index) + 1..-1]
      erb = ERB.new(template_contents, trim_mode: 1)
      res = erb.result(binding)

      to_file = "#{title}.#{suffix}" if title && suffix
      if to_file.nil?
        puts res
        @break = true
        return
      end

      update_file(to_file, res, **options)

    rescue => e # rubocop: disable all
      bt = e.backtrace
      lfatal "Exception was occured inside let_compile. bt = #{bt}"
      lfatal "class = #{e.class}"
      lfatal "message = #{e.message}"
      if !ENV['SHEEP_DEBUG_PRY'].nil?
        lfatal 'Entering pry debug session'
        binding.pry # rubocop: disable all
      else
        lfatal 'Not entering pry debug session.'
        lfatal 'Please define SHEEP_DEBUG_PRY for entering pry debug session'
        lfatal 'Critical. Exit'
        raise
      end
    end

    sig {
      params(
        namespace: String,
        title: String,
        options: T.untyped
      ).returns(String)
    }
    def construct_file_name(namespace, title, **options)
      namespace_sep = namespace_separator_file(**options)
      namespace.empty? ? title.to_s : "#{namespace}#{namespace_sep}#{title}"
    end

    # Give opotunity to define user_def structure
    sig {
      params(
        data: T.nilable(T::Hash[Symbol, T.untyped]),
        datastore: DataStore,
        template_file: T.nilable(String),
        options: T.untyped
      ).returns(T.untyped)
    }
    def user_def_compile(data, datastore, template_file, **options); end
  end
end
