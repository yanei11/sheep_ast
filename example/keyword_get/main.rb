# typed: false
# frozen_string_literal: true

require './lib/analyzer_core'
require 'rainbow/refinement'

using Rainbow

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
  tok.add_token tok.cmp('#', 'include')
  tok.add_token tok.cmp('/', '/')
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('ignore', A(:na)) {
      _SS(
        _S << space,
        _S << E(:sc, '//', "\n")
      )
    }
  }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show, { disable: true }], [:debug, { disable: true }])) {
      _SS(
        _S << E(:e, '#include') << E(:enc, '<', '>'),
        _S << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}')
      )
    }
    register_syntax(
      'analyze',
      A(:let, [:redirect, :test, 1..-2, { namespace: :_2 }], [:show, { disable: true }], [:debug, { disable: true }])
    ) {
      _SS(
        _S << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}', :test)
      )
    }
    register_syntax(
      'analyze',
      A(:let,
        [:record_kv_by_id, :ns_test_H, :_2, :_3, { namespace: true }],
        [:show, { disable: true }],
        [:debug, { disable: true }])
    ) {
      _SS(
        _S << E(:e, 'class') << E(:r, '.*') << E(:sc, '{', '}') << E(:e, ';')
      )
    }
  }
end

core.config_ast('always.ignore2') do |_ast, syn|
  syn.within {
    register_syntax('ignore', A(:na)) {
      _SS(
        _S << crlf,
        _S << lf,
        _S << eof
      )
    }
  }
end

core.report(raise: true) {
  core.analyze_file(['spec/scoped_match_file/test2.cc'])
}
p core.data_store.value(:ns_test_H)
