#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'match/scoped_match'
require 'analyzer_core'

describe Sheep::ScopedMatch do
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
        [[:sc, 'f', 'aaa', :test, end_reinput: true]]
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
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
        [[:sc, 'f', 'aaa', :test, end_reinput: true]]
      }
    end
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
    end

    expect {
      core << "f d"
      core << "aa"
      core << "c d aaa"
    }.to raise_error  Sheep::Exception::NotFound
  end
  it 'can detect nested scope' do
    core.config_ast('always.test') do |ast, syn, mf, af|
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
      syn.register(
        'match', 
        af.gen(:let,
               [:record_kv_by_id, :test_H, :test, :test],
               [:redirect, :test, 1..-2, namespace: 'test', ast_include: 'test']
              )
      ) {
        [[:sc, 'f', 'aaa', :test]]
      }
      syn.register(
        'match2', af.gen(:na)
      ) {
        [
          [:e, 'abc'],
          [:e, 'abc'],
          [:e, 'abc'],
        ]
      }
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
        [[:e, 'aaa']]
      }
    end
    core.config_ast('test.test') do |ast, syn, mf, af|
      syn.register(
        'test.test', 
        af.gen(:na)
      ) {
        [
          [:e, 'd'],
          [:e, 'aa'],
          [:e, 'f'],
          [:e, 'c'],
          [:e, 'd'],
          [:e, 'aaa'],
        ]
      }
    end

    expect {
      core.report(raise: true) {
        core << "f d"
        core << "aa f"
        core << "c d aaa aaa"
        core << "abc"
        core << "abc"
      }
    }.not_to raise_error
  end

  it 'can handle multiple nested scope' do
    core.config_tok do |tok|
      tok.add_token tok.cmp('#', 'include')
      tok.add_token tok.cmp('/', '/')
    end

    core.config_ast('always.ignore') do |ast, syn, mf, af|
      syn.within {
      register_multi('ignore', af.gen(:na)) {
          [
            _S << space,
            _S << E(:sc, '//', "\n")
          ]
        }
      }
    end

    core.config_ast('default.main') do |ast, syn, mf, af|
      syn.within {
        register_multi(
          'ignore', af.gen(
            :let,
            [:show, disable: true]
          )
        ) {
          [
           _S << E(:e, '#include') << E(:enc, '<', '>'),
           _S << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}'),
           _S << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}')
          ]
        }
      }
    end

    core.config_ast('always.ignore2') do |ast, syn, mf, af|
      syn.within {
        register_multi('ignore', af.gen(:na)) {
         [
            _S << crlf,
            _S << lf,
            _S << eof,
          ]
        }
      }
    end
 
    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/scoped_match_file/test1.cc'])
      }
    }.not_to raise_error
  end

  it 'can handle multiple nested scope by another way' do
    core.config_tok do |tok|
      tok.add_token tok.cmp('#', 'include')
      tok.add_token tok.cmp('/', '/')
    end

    core.config_ast('always.ignore') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:na)) {
          _SS(
            _S << space,
            _S << E(:sc, '//', "\n")
          )
        }
      }
    end

    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze', A(:let, [:show, disable: true], [:debug])) {
          _SS(
           _S << E(:e, '#include', :test1) << E(:enc, '<', '>', :test2),
           _S << E(:e, 'namespace', :test3) << E(:r, '.*', :test4) << E(:sc, '{', '}', :test5),
           _S << E(:e, 'int', :test6) << E(:e, 'main', :test7) << E(:enc, '(', ')', :test8) << E(:sc, '{', '}', :test9)
          )
        }
      }
    end

    core.config_ast('always.ignore2') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:let, [:show, disable: true])) {
          _SS(
             _S << crlf,
             _S << lf,
             _S << eof,
          )
        }
      }
    end
 
    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/scoped_match_file/test1.cc'])
      }
    }.not_to raise_error
  end

  it 'can handle multiple nested scope by another way2' do
    core.config_tok do |tok|
      tok.add_token tok.cmp('#', 'include')
      tok.add_token tok.cmp('/', '/')
    end

    core.config_ast('always.ignore') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:na)) {
          _SS(
            _S << space,
            _S << E(:sc, '//', "\n")
          )
        }
      }
    end

    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze', A(:let,[:show, disable: true], [:debug])) {
          _SS(
           _S << E(:e, '#include', :test1) << E(:enc, '<', '>', :test2),
           _S << E(:e, 'int', :test6) << E(:e, 'main', :test7) << E(:enc, '(', ')', :test8) << E(:sc, '{', '}', :test9),
          )
        }
        register_syntax('analyze', A(:let,[:redirect, :test5, 1..-2, namespace: :test4], [:show, disable: true], [:debug])) {
          _SS(
           _S << E(:e, 'namespace', :test3) << E(:r, '.*', :test4) << E(:sc, '{', '}', :test5),
          )
        }
        register_syntax('analyze', A(:let,[:record_kv_by_id, :ns_test_H, :test21, :test21, namespace: true], [:show, disable: true], [:debug])) {
          _SS(
           _S << E(:e, 'class') << E(:r, '.*', :test21) << E(:sc, '{', '}') << E(:e, ';')
          )
        }
      }
    end

    core.config_ast('always.ignore2') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:let, [:show, disable: true])) {
          _SS(
             _S << crlf,
             _S << lf,
             _S << eof,
          )
        }
      }
    end

    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/scoped_match_file/test2.cc'])
      }
    }.not_to raise_error
    # expect( core.data_store.value(:ns_test_H)['abc::bbb::ccc::test'] ).to eq('test')
    expect(core.data_store.value(:ns_test_H)).to eq({"abc::test3"=>"test3", "abc::bbb::test2"=>"test2", "abc::bbb::ccc::test"=>"test"})
  end

  it 'validates fail at eof' do
    core.config_tok do |tok|
      tok.add_token tok.cmp('#', 'include')
      tok.add_token tok.cmp('/', '/')
    end

    core.config_ast('always.ignore') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:na)) {
          _SS(
            _S << space,
            _S << E(:sc, '//', "\n")
          )
        }
      }
    end

    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze', A(:let, [:show, disable: true], [:debug])) {
          _SS(
           _S << E(:e, '#include', :test1) << E(:enc, '<', '>', :test2),
           _S << E(:e, 'namespace', :test3) << E(:r, '.*', :test4) << E(:sc, '{', '}', :test5),
           _S << E(:e, 'int', :test6) << E(:e, 'main', :test7) << E(:enc, '(', ')', :test8) << E(:sc, '{', '}', :test9)
          )
        }
      }
    end

    core.config_ast('always.ignore2') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:let, [:show, disable: true])) {
          _SS(
             _S << crlf,
             _S << lf,
             _S << eof,
          )
        }
      }
    end

    expect {
      core.analyze_file(['spec/scoped_match_file/test3.cc'])
    }.to raise_error Sheep::Exception::ApplicationError
  end

end
