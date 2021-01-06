# typed: true
# frozen_string_literal:true

require 'erb'
require 'sorbet-runtime'
require 'rainbow/refinement'

using Rainbow

module SheepAst
  # module to enable compile from a file to a file.
  module LetCompile
    extend T::Sig
    extend T::Helpers

    # It uses erb library for embedd variable.
    # Please use erb syntax for the template_file.
    #
    # @example
    #   A(:let, [:compile, from_file, [options]])
    #
    # redirect specified data to specified Ast. The data can be specified by tag and by specified range.
    # Specified data will be iput again.  Ast stage to process the data can be specified at option.
    # The Ast specifying can be done by domain or full name of Ast Stage.
    #
    # @option options [Boolean] :dry_run print variables that can be userd in the erb.
    #                            With this option, only print is printed and not generating file
    # @option options [String]  :mode Set File mode. default value is 'a'
    # @option options [Integer] :perm Set File permission. default value is 0600
    #
    sig {
      params(
        data: T.nilable(T::Hash[Symbol, T.untyped]),
        datastore: DataStore,
        template_file: T.nilable(String),
        options: T.untyped
      ).returns(T.nilable(T::Boolean))
    }
    def compile(data, datastore, template_file = nil, **options) # rubocop:disable all
      if !data.nil?
        namespace = w_or_wo_ns(data, { **options, namespace: true })
        namespace_arr = data[:_namespace]
      end

      if !template_file.nil?
        raw = File.read(template_file)
        head_index = raw.index("\n")
        head = raw[0..head_index - 1]
        partitioned = head.split('!')[1].rpartition('.')
        suffix = partitioned.last
        title = binding.eval(partitioned.first) # rubocop:disable all
      end

      user_def = user_def_compile(data, datastore, template_file, **options)

      if options[:dry_run]
        _format_dump {
          ldump "data : #{data.inspect}"
          ldump "namespace : #{namespace.inspect}"
          ldump "namespace_arr : #{namespace_arr.inspect}"
          ldump "user_def : #{user_def.inspect}"
          ldump "erb_head : #{head}"
          ldump "title : #{title}"
          ldump "suffix : #{suffix}"
        }
        return _ret(**options)
      end

      ldebug '=== compile debug ==='
      ldebug "data : #{data.inspect}"
      ldebug "namespace : #{namespace.inspect}"
      ldebug "namespace_arr : #{namespace_arr.inspect}"
      ldebug "user_def : #{user_def.inspect}"
      ldebug "erb_head : #{head}"
      ldebug "title : #{title}"
      ldebug "suffix : #{suffix}"
      ldebug '=== end ==='

      template_contents = raw[head_index + 1..-1]
      erb = ERB.new(template_contents, trim_mode: 1)
      res = erb.result(binding)

      to_file = "#{title}.#{suffix}" if title && suffix
      if to_file.nil?
        puts res
        return _ret(**options)
      end

      update_file(to_file, res, **options)
      return _ret(**options)
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
      end
      return _ret(**options)
    end

    def construct_file_name(namespace, title, **options)
      namespace_sep = _namespace_separator_file(**options)
      namespace ? "#{namespace}#{namespace_sep}#{title}" : title.to_s
    end

    # Give opotunity to define user_def structure
    def user_def_compile(data, datastore, template_file, **options); end

    def update_file(file, res, **options)
      if File.exist?(file)
        ftime = File.ctime(file)
        test = ctime_get <=> ftime
        case test
        when 1
          ldebug "#{file} is created before application launch. Delete it first!"
          File.delete(file)
        when -1
          # lprint "#{file} is created after factory created. Nothing to do."
        else
          lfatal "Unexpected timestamp info. #{ctime_get}, "\
            "file = #{ftime}, test = #{test.inspect}"
          application_error
        end
      end

      mode = options[:mode]
      perm = options[:perm]
      mode = 'a' if mode.nil?
      if perm.nil?
        File.open(file, mode) { |f|
          f.write(res)
        }
      else
        File.open(file, mode, perm) { |f|
          f.write(res)
        }
      end
    end
  end
end
