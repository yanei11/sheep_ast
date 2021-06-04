#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::Let do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can handle multiple nested scope by another way2' do
    Dir.mkdir('spec/res') unless Dir.exist?('spec/res')

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
        register_syntax('analyze', A(:let,[:show, disable: true])) {
          _SS(
           _S << E(:e, '#include') << E(:enc, '<', '>'),
           _S << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}'),
          )
        }
        register_syntax(
          'analyze',
          A(:let,
            [:redirect, :_3, 1..-2, namespace: :_2],
            [:show, disable: true]
           )
        ) {
          _SS(
           _S << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}'),
          )
        }
        register_syntax(
          'analyze',
          A(:let,
            [:record, :test_A, :_2, namespace_value: true], 
            [:compile, 'spec/unit/test_files/template1.erb', dry_run: false, namespace_separator: '_', namespace_separator_file: '_' ], 
            [:show, disable: true])) {
          _SS(
           _S << E(:e, 'class') << E(:r, '.*') << E(:sc, '{', '}') << E(:e, ';')
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
        core.analyze_file(['spec/unit/scoped_match_file/test4.cc'])
      }
    }.not_to raise_error
  end
end
