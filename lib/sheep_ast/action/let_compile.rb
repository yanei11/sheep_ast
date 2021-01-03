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
    # @option options [Boolean] :debug it prints variables that can be userd in the erb
    #
    sig {
      params(
        data: T::Hash[Symbol, T.untyped],
        datastore: DataStore,
        template_file: String,
        options: T.untyped
      ).void
    }
    def compile(data, datastore, template_file, **options) # rubocop:disable all
      raw = File.read(template_file)
      head_index = raw.index("\n")
      head = raw[0..head_index - 1]

      p head.split('!')
      partitioned = head.split('!')[1].rpartition('.')
      p partitioned
      suffix = partitioned.last
      template_contents = raw[head_index + 1..-1]
      namespace = w_or_wo_ns(data, { namespace: true })
      namespace_arr = data[:_namespace]
      user_def = user_def_compile(data, datastore, template_file, **options)
      title = binding.eval(partitioned.first) # rubocop:disable all
      if options[:debug]
        _format_dump {
          ldump "data : #{data.inspect}"
          ldump "namespace : #{namespace.inspect}"
          ldump "namespace_arr : #{namespace_arr.inspect}"
          ldump "user_def : #{user_def.inspect}"
          ldump "erb_head : #{head}"
          ldump "title : #{title}"
          ldump "suffix : #{suffix}"
        }
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

      erb = ERB.new(template_contents)
      res = erb.result(binding)

      to_file = "#{title}.#{suffix}" if title && suffix
      if to_file.nil?
        puts res
        return
      end

      perm = options[:perm]
      if perm.nil?
        File.open(to_file, 'w') { |f|
          f.write(res)
        }
      else
        File.open(to_file, 'w', perm) { |f|
          f.write(res)
        }
      end
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
    end

    def construct_file_name(namespace, title)
      namespace ? "#{namespace}::#{title}" : title.to_s
    end

    # Give opotunity to define user_def structure
    def user_def_compile(data, datastore, template_file, **options); end
  end
end
