#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::ScopedMatch do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can be created' do
    core.config_ast('default.test') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
        [
          syn.space,
          syn.crlf,
          syn.lf,
          syn.eocf
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
        syn._S << syn.E(:sc, 'f', 'aaa', :test, end_reinput: true)
      }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:na)) {
        syn._S << syn.E(:e, 'aaa')
      }
    end
    expect {
      core << "f d"
      core << "aa"
      core << "c d aaa"
    }.not_to raise_error
  end
  # it 'should occur not found error' do
  #   core.config_ast('default.test2') do |ast, syn, mf, af|
  #     syn.register_syntax('match', syn.A(:na)) {
  #       syn._S << syn.E(:sc, 'f', 'aaa', :test, end_reinput: true)
  #     }
  #   end
  #   core.config_ast('default.test') do |ast, syn, mf, af|
  #     syn.within {
  #     register_syntax('ignore', A(:na)) {
  #       _SS(
  #         _S << space,
  #         _S << crlf,
  #         _S << lf,
  #         _S << eof
  #       )
  #     }
  #     }
  #   end

  #   expect {
  #     core << "f d"
  #     core << "aa"
  #     core << "c d aaa"
  #   }.to raise_error  SheepAst::Exception::NotFound
  # end
  it 'can detect nested scope' do
    core.config_ast('always.test') do |ast, syn, mf, af|
      syn.register_syntax('ignore', syn.A(:na)) {
       [
          syn._S << syn.space,
          syn._S << syn.crlf,
          syn._S << syn.lf,
          syn._S << syn.eocf
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
      syn.register_syntax(
        'match', 
        syn.A(:let,
               [:record, :test_H, :test, :test],
               [:redirect, :test, 1..-2, namespace: 'test', meta1: 'test1', meta2: 'test2', ast_include: 'test']
              )
      ) {
        syn._S << syn.E(:sc, 'f', 'aaa', :test)
      }
      syn.register_syntax(
        'match2', syn.A(:na)
      ) {
        [
          syn.E(:e, 'abc'),
        ]
      }
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:na)) {
        [syn.E(:e, 'aaa')]
      }
    end
    core.config_ast('test.test') do |ast, syn, mf, af|
      syn.register_syntax(
        'test.test', 
        syn.A(:na)
      ) {
        syn._SS(
          syn._S << syn.E(:e, 'd') << syn.E(:e, 'aa') << syn.E(:e, 'f') <<
                    syn.E(:e, 'c')  << syn.E(:e, 'd') <<  syn.E(:e, 'aaa')
        )
      }
    end

    expect {
      core.report(raise: false) {
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
        register_syntax(
          'ignore', A(
            :let,
            [:show, disable: true]
          )
        ) {
          _SS(
           _S << E(:e, '#include') << E(:enc, '<', '>'),
           _S << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}'),
           _S << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}')
          )
        }
      }
    end

    core.config_ast('always.ignore2') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:na)) {
         _SS(
            _S << crlf,
            _S << lf,
            _S << eocf,
         )
        }
      }
    end
 
    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/unit/scoped_match_file/test1.cc'])
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
        register_syntax('analyze', A(:let, [:show, disable: true], [:debug, disable: true])) {
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
             _S << eocf,
          )
        }
      }
    end
 
    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/unit/scoped_match_file/test1.cc'])
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
        register_syntax('analyze', A(:let,[:show, disable: true], [:debug, disable: true])) {
          _SS(
           _S << E(:e, '#include', :test1) << E(:enc, '<', '>', :test2),
           _S << E(:e, 'int', :test6) << E(:e, 'main', :test7) << E(:enc, '(', ')', :test8) << E(:sc, '{', '}', :test9),
          )
        }
        register_syntax('analyze', A(:let,[:redirect, :test5, 1..-2, namespace: :test4], [:show, disable: true], [:debug, disable: true])) {
          _SS(
           _S << E(:e, 'namespace', :test3) << E(:r, '.*', :test4) << E(:sc, '{', '}', :test5),
          )
        }
        register_syntax('analyze', A(:let,
                                     [:record, :ns_test_HL, :test21, :test21, namespace_key: true], 
                                     [:record, :ns_test_H, :test21, :test21, namespace_key: true], 
                                     [:record, :ns_test_HA, :test21, [:test21, :test21], namespace_key: true], 
                                     [:show, disable: true], [:debug, disable: true])) {
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
             _S << eocf,
          )
        }
      }
    end

    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/unit/scoped_match_file/test2.cc'])
      }
    }.not_to raise_error
    expect(core.data_store.value(:ns_test_HL).data).to eq({"abc::test3"=>"test3", "abc::bbb::test2"=>"test2", "abc::bbb::ccc::test"=>"test"})
    expect(core.data_store.value(:ns_test_H).data).to eq({"abc::test3"=>["test3"], "abc::bbb::test2"=>["test2"], "abc::bbb::ccc::test"=>["test"]})
    expect(core.data_store.value(:ns_test_HA).data).to eq({"abc::test3"=>[["test3", "test3"]], "abc::bbb::test2"=>[["test2", "test2"]], "abc::bbb::ccc::test"=>[["test", "test"]]})
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
        register_syntax('analyze', A(:let, [:show, disable: true], [:debug, disable: true])) {
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
             _S << eocf,
          )
        }
      }
    end

    expect {
      core.analyze_file(['spec/unit/scoped_match_file/test3.cc'])
    }.to raise_error SheepAst::Exception::ApplicationError
  end

  it 'can match multiple condition' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:let, [:record, :test_A, :_1])) {
        syn._S << syn.E(:enc, 'a', "\n", end_cond: syn.idx('i', 'j', 'k'))
      }
    end

    core.config_ast('always.ignore') do |ast, syn, mf, af|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          syn._SS(
            syn._S << syn.E(:any)
         )
       }
      }
    end

    expect {
      core.report(raise: true ) {
      core << "a b c d
               a f g h
               i j k"
      core << '__sheep_eof__'
    }
    }.not_to raise_error
  end
end
