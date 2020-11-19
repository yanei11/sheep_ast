# typed: false
# rubocop:disable all
# -*- encoding: utf-8 -*-

require 'spec_helper'
require 'log'

class Child
  include Sheep::Log
end

describe Child do
  let(:log) { Child.new }
  describe '#reset_lger' do
    it 'works' do
      log.set_logger(Logger::FATAL, nil)
      expect(log).not_to be_nil
      log.linfo('test')
      # log.lfatal('test')
      log.lwarn('test')
      log.lerror('test')
      log.ldebug('test')
    end
  end
end
