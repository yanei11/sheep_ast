#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'match/scoped_match'
require 'analyzer_core'

describe Sheep::EnclosedMatch do
  let(:core) { Sheep::AnalyzerCore.new }
  it 'can be created' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
        [[:enc, 'f', 'aaa', :test, end_reinput: true]]
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
        [[:e, 'aaa']]
      }
    end
    expect {
      core << "f d"
      core << "aa"
      core << "c d aaa"
    }.not_to raise_error
  end
  it 'should occur not found error' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
        [[:enc, 'f', 'aaa', :test, end_reinput: true]]
      }
    end

    # expect {
    #   core << "f d"
    #   core << "aa"
    #   core << "c d aaa"
    # }.to raise_error Sheep::Exception::NotFound
  end
  it 'enclosed match ignore scope unlike scoped match' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
        [[:enc, 'f', 'aaa', :test, end_reinput: true]]
      }
    end
    # expect {
    #   core << "f d"
    #   core << "aa f"
    #   core << "c d aaa aaa"
    # }.to raise_error Sheep::Exception::NotFound
  end
end
