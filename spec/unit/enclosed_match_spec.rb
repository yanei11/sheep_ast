#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::EnclosedMatch do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can be created' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
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
          return SheepAst::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
      register_syntax('match', A(:na)) {
        _SS( _S << E(:enc, 'f', 'aaa', :test, end_reinput: true))
      }
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
      register_syntax('match', syn.A(:na)) {
        _S << E(:e, 'aaa')
      }
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
      syn.register_syntax('ignore', syn.A(:na)) {
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
          return SheepAst::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:na)) {
        syn._S << syn.E(:enc, 'f', 'aaa', :test, end_reinput: true)
      }
    end

    # expect {
    #   core << "f d"
    #   core << "aa"
    #   core << "c d aaa"
    # }.to raise_error SheepAst::Exception::NotFound
  end
  it 'enclosed match ignore scope unlike scoped match' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        syn._SS(
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        )
      }
      ast.within do
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return SheepAst::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:na)) {
        syn._S << syn.E(:enc, 'f', 'aaa', :test, end_reinput: true)
      }
    end
    # expect {
    #   core << "f d"
    #   core << "aa f"
    #   core << "c d aaa aaa"
    # }.to raise_error SheepAst::Exception::NotFound
  end
  it 'enclosed regex match ignore scope unlike scoped match' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        syn._SS(
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        )
      }
      ast.within do
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return SheepAst::MatchAction::Continue
        end
      end
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:na)) {
        syn._S << syn.E(:encr, 'f.*', 'aaa')
      }
    end

    expect {
      core << "f d"
      core << "aa f"
      core << "c d aaa"
    }.not_to raise_error
  end
end
