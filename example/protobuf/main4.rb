# typed: false
# frozen_string_literal: true

require './lib/sheep_ast'

debug_off = false
dry1 = false
dry2 = false

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
        _S << E(:e, 'syntax') << E(:e, '=') << E(:e, '"')\
                              << E(:e, 'proto2') << E(:e, '"') << E(:e, ';'),
        _S << E(:e, 'package') << E(:any) << E(:e, ';')
      )
    }
  }
end

core.config_ast('message.parser') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:e, 'optional') << E(:any, { repeat: 4 }) << E(:e, ';')\
                                << A(:let, [:show, { disable: debug_off }]),
        _S << E(:e, 'optional') << E(:any, { repeat: 4 }) << E(:e, '[')\
                                << E(:any, { repeat: 4 }) << E(:e, ';')\
                                << A(:let, [:show, { disable: debug_off }]),
        _S << E(:e, 'repeated') << E(:any, { repeat: 4 }) << E(:e, ';')\
                                << A(:let, [:show, { disable: debug_off }]),
        _S << E(:e, 'repeated') << E(:any, { repeat: 4 }) << E(:e, '[')\
                                << E(:any, { repeat: 4 }) << E(:e, ';')\
                                << A(:let, [:show, { disable: debug_off }])
      )
    }
  }
end

core.config_ast('enum.parser') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:any, { at_head: true }) <<  E(:any, { repeat: 2 }) << E(:e, ';')\
                                         << A(:let, [:show, { disable: debug_off }])
      )
    }
  }
end

core.config_ast('default.parse1') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:e, 'message') << E(:any) << E(:sc, '{', '}') \
           << A(:let, [:redirect, :_3, 2..-2, { dry_run: dry1, namespace: :_2, ast_include: ['default', 'message'] }]),
        _S << E(:e, 'enum') << E(:any) << E(:sc, '{', '}') \
           << A(:let, [:redirect, :_3, 2..-2, { dry_run: dry2, namespace: :_2, ast_include: ['enum'] }])
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
