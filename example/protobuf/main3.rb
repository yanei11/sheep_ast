# typed: false
# frozen_string_literal: true

require './lib/sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, ' ')
      )
    }
  }
end

core.config_ast('default.ignore_syntax') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show, { disable: true }])) {
      _SS(
        _S << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2') << E(:e, '"') << E(:e, ';'),
        _S << E(:e, 'package') << E(:any) << E(:e, ';')
      )
    }
  }
end

core.config_ast('default.parse1') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:redirect, :_3, 2..-2, { dry_run: true, namespace: :_2 }])) {
      _SS(
        _S << E(:e, 'message') << E(:any) << E(:sc, '{', '}')
      )
    }
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, "\n"),
        _S << E(:eof)
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
