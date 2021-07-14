#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::AnalyzerCore do # rubocop: disable all
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can be ceated' do
    ast = core.config_ast('default.test') do |_ast, _syn, _mf, _af|; end
    expect(core.from_id(ast.my_id).object_id).to eq(
      core.from_name('default.test').object_id
    )
  end
  it 'can be created and add some matches' do # rubocop: disable all
    core.config_ast('default.test') do |ast, syn, mf, af|
      matches = []
      mf.within do
        matches << gen(:e, 'c', :test)
      end
      action = af.gen(:na)
      ast.add(matches, action, 'test')
    end

    core.config_ast('default.test') do |ast, syn, mf, af|
      matches = []
      mf.within do
        matches << gen(:e, 'f', :test) << gen(:e, 'd', :test2) <<
          gen(:e, 'e', :test3) << gen(:e, 'f', :test4)
      end
      action = af.gen(:na)
      ast.add(matches, action, 'test2')
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      matches = [
        [:e, 'f'], [:e, 'd'], [:r, '.*']
      ].map { |arg| mf.gen(*arg) }
      action = af.gen(:na)
      ast.add(matches, action, 'test2')
    end

    core.config_ast('default.test3') do |ast, syn, mf, af|
      syn.within {
        register_syntax('default.test') { _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*') << A(:na) }
      }
    end

    core.config_ast('default.test4') do |ast, syn, mf, af|
      syn.within {
      register_syntax {
        _SS(
          _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*') << A(:na),
          _S << E(:e, 'a') << E(:e, 'b') << E(:r, '...') << E(:r, '##a') << A(:na)
        )
      }
      }
    end

    core.config_ast('default.test5') do |ast, syn, mf, af|
      syn.within {
        register_syntax('default.test', A(:na)) { _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*') }
      }
    end

    core.config_ast('default.test6') do |ast, syn, mf, af|
      syn.within {
      register_syntax(A(:na)) {
        _SS(
          _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*'),
          _S << E(:e, 'a') << E(:e, 'b') << E(:r, '...') << E(:r, '##a')
        )
      }
      }
    end

    core.config_ast('default.test7') do |ast, syn, mf, af|
      syn.within {
      register_syntax('default.test') {
        _SS( 
          _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*') << A(:na),
          _S << E(:e, 'a') << E(:e, 'b') << E(:r, '...') << E(:r, '##a') << A(:na)
        )
      }
      }
    end
    core.dump(:pdebug)
  end

  it 'will raise exception when duplicated match' do
    core.config_ast('default.test7') do |ast, syn, mf, af|
      expect {
        syn.within {
        register_syntax('default.test') {
          _SS(
            _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*') << A(:na),
            _S << E(:e, 'f') << E(:e, 'd') << E(:r, '.*') << A(:na)
          ) 
        }
        }
      }.to raise_error SheepAst::Exception::ApplicationError
    end
  end

  it 'can parse file' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        syn._SS(
          syn._S << syn.space,
          syn._S << syn.crlf,
          syn._S << syn.lf,
          syn._S << syn.eolcf
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
      syn.within {
      register_syntax('match', A(:na)) {
          _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa') << E(:e,'ddd')
      }
      }
    end
    core.dump(:pdebug)
    expect { core << "f d aa 
    ddd" }.not_to raise_error
  end

  it 'can parse file' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        syn._SS(
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eolcf
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
      syn.within {
      register_syntax('match', A(:na)) {
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa') << E(:e,'ddd'))
      }
      }
    end
    core.dump(:pdebug)
    expect { core << "f d aa 
    ddd" }.not_to raise_error
  end

  it 'can catch exception' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        syn._SS(
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eolcf
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
      syn.within {
      register_syntax('match', A(:na)) {
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    core.report(:ldebug) {
      core << "f d aa 
      ddd"
    }
  end
  it 'parse multiple expr' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eolcf
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
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    core.report(:ldebug) {
      core << "f d"
      core << "aa"
      core << "f d aa"
    }
  end
  it 'validation fail when eof' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eolcf
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
          _SS( _S << E(:e, 'f') << E(:e, 'd') << E(:e, 'aa'))
      }
      }
    end
    expect {
      core << "f d"
      core << "aa"
      core << "f d "
      core << "__sheep_eof__"
    }.to raise_error SheepAst::Exception::ApplicationError
  end
end
