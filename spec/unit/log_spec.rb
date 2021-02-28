# typed: false
# frozen_string_literal: true
# rubocop:disable all

require 'spec_helper'
require 'sheep_ast'

class Child
  include SheepAst::Log
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
