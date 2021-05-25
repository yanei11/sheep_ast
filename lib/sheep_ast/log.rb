# typed: false
# frozen_string_literal: true

require 'logger'
require 'rainbow/refinement'
require 'sorbet-runtime'
require 'time'

using Rainbow

# Overwrite inspect to stop verbose print
class Logger
  def inspect; end
end

module SheepAst
  # Logger Wrapper module
  #
  # @api private
  #
  # rubocop:disable all
  module Log
    extend T::Sig
    include Kernel
    class << self
      extend T::Sig
    end

    sig { returns(Logger) }
    attr_accessor :logger

    sig { void }
    def initialize
      @loglevel = 0
      lev = level_get
      dev = device_get
      @stack_base = stack_base_get
      set_logger(lev, dev)
      super()
    end

    sig { params(msg: String, color_: Symbol).void }
    def pinfo(msg = '', color_ = :antiquewhite)
      @logger.info msg.color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def pfatal(msg = '', color_ = :antiquewhite)
      @logger.fatal msg.color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def pdebug(msg = '', color_ = :antiquewhite)
      @logger.debug msg.color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def lprint(msg = '', color_ = :yellow)
      str = 'P: '
      str += say_class_name + msg
      puts str.color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def ldump(msg = '', color_ = :pink)
      str = msg.color(color_)
      puts str.color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def linfo(msg = '', color_ = :antiquewhite)
      @logger.info (say_class_name + msg).color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def pwarn(msg = '', color_ = :antiquewhite)
      @logger.warn msg.color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def lwarn(msg = '', color_ = :antiquewhite)
      @logger.warn (say_class_name + msg).color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def lfatal(msg = '', color_ = :antiquewhite)
      @logger.fatal (say_class_name + msg).color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def lerror(msg = '', color_ = :antiquewhite)
      @logger.error (say_class_name + msg).color(color_)
    end

    sig { params(msg: String, color_: Symbol).void }
    def ldebug2(msg = '', color_ = :antiquewhite)
      env = ENV['SHEEP_LOG_LEVEL']
      return if env.nil?

      if env >= 2
        ldebug msg.color(color_)
      end
    end

    sig { returns(T::Boolean) }
    def ldebug?
      return @loglevel >= 2
    end

    sig { returns(T::Boolean) }
    def lprint?
      return true
    end

    sig { params(msg: String, color_: Symbol).void }
    def ldebug(msg = '', color_ = :antiquewhite)
      if !ENV['SHEEP_LOG_BT'].nil?
        at = caller[@stack_base]
        if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
          file = $1 # rubocop: disable all
          line = $2.to_i # rubocop: disable all
        end
        @logger.debug "#{say_class_name} #{msg}"\
          " (at #{File.basename(file)}:#{line})".color(color_)
      else
        @logger.debug "#{say_class_name} #{msg}".color(color_)
      end
    end

    sig { params(level: Integer, device: T.any(NilClass, IO, String)).void }
    def set_logger(level, device = nil)
      device = $stdout if device.nil?
      dev = T.cast(device, T.any(IO, String))
      @logger = Logger.new(dev)
      @logger.level = level
      @logger.formatter = logformatter
    end

    sig { params(sym: Symbol, blk: T.proc.void).void }
    def once(sym, &blk)
      if !instance_variable_defined? sym
        blk.call
        instance_variable_set sym, true
      end
    end

    private

    # @api private
    sig { returns(String) }
    def class_name
      return T.unsafe(self).class.name.split('::').last
    end

    # @api private
    sig { returns(String) }
    def say_class_name
      "#{class_name}> "
    end

    # @api private
    sig {
      returns(T.nilable(T.proc.params(
        sev: Integer,
        tim: Time,
        progname: T.nilable(String),
        msg: T.untyped
      ).returns(T.untyped)))
    }
    def logformatter
      proc { |sev, _, _, message|
        case sev
        when 'DEBUG'
          sevr = T.unsafe('D').blue
        when 'ERROR'
          sevr = T.unsafe('E').bg(:red)
        when 'FATAL'
          sevr = T.unsafe('F').magenta
        when 'WARN'
          sevr = T.unsafe('W').color(:indianred)
        when 'INFO'
          sevr = T.unsafe('I')
        else
          sevr = sev
        end

        if !ENV['SHEEP_LOG_MICRO'].nil?
          time = Time.now
          sevr = "#{sevr}[#{time.iso8601(6)}]"
        end
        "#{sevr}: #{message}\n"
      }
    end

    # @api private
    sig { returns(Integer) }
    def level_get
      env = ENV['SHEEP_LOG']
      case env
      when 'DEBUG'
        @loglevel = 2
        return Logger::DEBUG
      when 'INFO'
        @loglevel = 1
        return Logger::INFO
      else
        @loglevel = 0
        return Logger::WARN
      end
    end

    # @api private
    sig { returns(T.nilable(String)) }
    def device_get
      env = ENV['SHEEP_LOG_PATH']
      return nil if env.nil? || env.empty?
    end

    # @api private
    sig { returns(Integer) }
    def stack_base_get
      env = ENV['SHEEP_LOG_STACK_BASE']
      return 0 if env.nil? || env.empty?

      return env.to_i
    end
  end
end
