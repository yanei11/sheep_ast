#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'match/scoped_match'
require 'analyzer_core'

describe Sheep::ScopedMatch do
  let(:core) { Sheep::AnalyzerCore.new }
  it 'can be created' do
    core.config_ast('test') do |ast, _tok, mf, af, syn|
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
    core.config_ast('test2') do |ast, _tok, mf, af, syn|
      syn.register('match', af.gen(:na)) {
        [[:sc, 'f', 'aaa', :test, end_reinput: true]]
      }
    end

    core.config_ast('test2') do |ast, _tok, mf, af, syn|
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
end
