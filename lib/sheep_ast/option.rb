# typed:ignore
# frozen_string_literal:true

require 'optparse'
require_relative 'exception'

# api public
module SheepAst
  # Aggregates User interface of sheep_ast library
  #
  # @api public
  module Option
    # NOTE
    # Do not include Log or Exception module here.
    # Since this module could be included from other users.
    # It result with conflict of user module.
    extend T::Sig

    def option_on
      @option = {}
      #rubocop: disable all
      @optparse = OptionParser.new do |opt|
        opt.on(
          '-E array', Array,
          'Specify directories to exclude files'
        ) { |v| @option[:E] = v }
        opt.on(
          '-I array', Array, 'Specify search directories for the include files'
        ) { |v| @option[:I] = v }
        opt.on(
          '-F files', Array, 'Specify file to filter to include'
        ) { |v| @option[:F] = v }
        opt.on(
          '-d', 'Dump Debug information'
        ) { @option[:d] = true }
        opt.on(
          '-r files', Array, 'Specify configuration ruby files'
        ) { |v| @option[:r] = v }
        opt.on(
          '-o path', 'outdir variable is set in the let_compile module'
        ) { |v| @option[:o] = v }
        opt.on(
          '-t array', Array,
          'Specify search directories for the template files for let_compile module'
        ) { |v| @option[:t] = v }
        opt.on_tail(
          '-h', '--help', 'show usage'
        ) { |_v| @option[:h] = true }
        opt.on_tail(
          '-s', '--skip', 'skip analyze'
        ) { |_v| @option[:s] = true }
        opt.on_tail(
          '-v', '--version', 'show version'
        ) { |_v| @option[:v] = true }
      end
      return @optparse
    end

    # Command line option
    #
    # @api private
    #
    # @example
    #   ruby your_app.rb -h # shows usage
    #
    # rubocop:disable all
    sig {
      params(argv: T::Array[String]).returns(
        T.nilable(T::Hash[Symbol, T.untyped])
      )
    }
    def option_parse(argv)
      @optparse.parse!(argv)
      show_usage
      show_version
      load_config
      return @option
    end

    def show_usage
      if @option[:h]
        command
        usage
        exit
      end
    end

    def show_version
      if @option[:v]
        puts SheepAst::VERSION
        exit
      end
    end

    def ruby_version
      "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
    end

    def load_config
      if @loaded_file.nil?
        @loaded_file = []
      end
      config_file = @option[:r]
      if config_file
        @configure_count = 0
        config_file.each_with_index do |file, index|
          if File.exist?(file)
            require file
            if defined? configure
              alias :"configure_#{index}" :configure
              @loaded_file << file.split('/').last
              @configure_count += 1
            end
          else
            raise "#{config_file} could not be found at the specified directory."
          end
        end
      else
        return nil
      end
    end

    def command
      if @optparse
        puts ''
        puts "Usage: #{@optparse.program_name} [options] arg1, arg2, ..."
        puts '    arg1, arg2, ... : specify files to parse.'
      end
    end

    def usage
      if @optparse
        puts ''
        @optparse.banner = 'Available options :'
        puts @optparse.help
        puts ''
      end
    end

    def option
      @option
    end

    def set_option(opt, optp)
      @option = opt
      @optparse = optp
    end

    def do_configure(core, option = nil, optparse = nil)
      return false if @configure_count.zero?

      (0..@configure_count - 1).each do |count|
        core.set_option(option, optparse)
        method(:"configure_#{count}").call(core)
      end

      puts "#{@optparse.program_name}> Files contains configure is #{@configure_count}"
      puts "#{@optparse.program_name}> Loaded files are #{@loaded_file.inspect}"
      return true
    end
  end
end
