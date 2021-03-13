# typed:ignore
# frozen_string_literal:true

require 'optparse'

# api public
module SheepAst
  # Aggregates User interface of sheep_ast library
  #
  # @api public
  module Option
    extend T::Sig

    def option_on
      @option = {}
      @optparse = OptionParser.new do |opt|
        opt.on(
          '-E array', Array,
          'Specify directories to exclude files'
        ) { |v| @option[:E] = v }
        opt.on(
          '-I array', Array, 'Specify search directories for the include files'
        ) { |v| @option[:I] = v }
        opt.on(
          '-d', 'Dump Debug information'
        ) { @option[:d] = true }
        opt.on(
          '-r file', 'Specify configuration ruby file'
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
        AnalyzerCore.usage
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
      config_file = @option[:r]
      if config_file
        if File.exist?(config_file)
          load config_file
        else
          application_error "#{config_file} could not be found at the specified directory."
        end
      else
        return nil
      end
    end

    def usage
      if @optparse
        puts ''
        puts "Usage: #{@optparse.program_name} [options] arg1, arg2, ..."
        puts '    arg1, arg2, ... : specify files to parse.'
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
      if defined? configure
        core.set_option(option, optparse)
        configure(core)
        return true
      end
      return false
    end
  end
end
