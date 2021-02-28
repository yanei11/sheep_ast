# typed: ignore
# frozen_string_literal: true
# rubocop:disable all

require 'sheep_ast'

def configure(core)
  core.config_tok do |tok|
    tok.token_rule('#', 'include')
    tok.token_rule('/', '/')
  end

  core.config_ast('always.ignore') do |_ast, syn|
    syn.within {
      register_syntax('ignore', A(:na)) {
        SS(
          S() << space,
          S() << E(:sc, '//', "\n")
        )
      }
    }
  end

  core.config_ast('default.main') do |_ast, syn|
    syn.within {
      register_syntax('analyze', A(:let, [:show, disable: true], [:debug, disable: true])) {
        SS(
          S() << E(:e, '#include') << E(:enc, '<', '>'),
          S() << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}')
        )
      }
      register_syntax(
        'analyze',
        A(:let, [:redirect, :test, 1..-2, namespace: :_2], [:show, disable: true], [:debug, disable: true])
      ) {
        SS(
          S() << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}', :test)
        )
      }
      register_syntax(
        'analyze',
        A(:let,
          [:record, :ns_test_H, :_2, :_3, namespace_key: true],
          [:show, disable: true],
          [:debug, disable: true])
      ) {
        SS(
          S() << E(:e, 'class') << E(:r, '.*') << E(:sc, '{', '}') << E(:e, ';')
        )
      }
    }
  end

  core.config_ast('always.ignore2') do |_ast, syn|
    syn.within {
      register_syntax('ignore', A(:na)) {
        SS(
          S() << crlf,
          S() << lf,
          S() << eof
        )
      }
    }
  end
end

if __FILE__ == $PROGRAM_NAME
  core = SheepAst::AnalyzerCore.new
  configure(core)
  core.report(raise: true) {
    core.analyze_file(['spec/unit/scoped_match_file/test2.cc'])
  }
  p core.data_store.value(:ns_test_H)
end
