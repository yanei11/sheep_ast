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

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show])) {
      _SS(
        _S << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2') << E(:e, '"') << E(:e, ';')
      )
    }
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, "\n")
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
