#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::AnalyzerCore do # rubocop: disable all
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'raise not found error' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eocf
        ]
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
      register_syntax('match', A(:na)) {
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    expect {
      core << "f d"
      core << "aa"
      core << "f g "
    }.to raise_error SheepAst::Exception::NotFound
  end

  it 'does not raise not found error when it is configured' do
    core.not_raise_when_all_ast_not_found

    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eocf
        ]
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
      register_syntax('match', A(:na)) {
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    res = core << "f d"
    res = core << "aa"
    res = core << "f g "
    expect(res.result).to eq(SheepAst::MatchResult::NotFound)
  end

  it 'returns finish when it reaches to an Action' do
    core.not_raise_when_all_ast_not_found

    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eocf
        ]
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
      register_syntax('match', A(:na)) {
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    res = core << "f d"
    res = core << "aa"
    expect(res.result).to eq(SheepAst::MatchResult::Finish)
  end

  it 'returns get next when it does not reache to an Action, but it does not not found' do
    core.not_raise_when_all_ast_not_found

    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eocf
        ]
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
      register_syntax('match', A(:na)) {
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    res = core << "f d"
    expect(res.result).to eq(SheepAst::MatchResult::GetNext)
  end
end
