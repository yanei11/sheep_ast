# typed: ignore
# frozen_string_literal: true

require 'sheep_ast'

template1 = 'example/protobuf/template_message.erb'
template2 = 'example/protobuf/template_enum.erb'
action1 = [:compile, template1, { dry_run: false }]
action2 = [:compile, template2, { dry_run: false }]
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
    register_syntax('analyze') {
      _SS(
        _S << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2')\
           << E(:e, '"') << E(:e, ';') << A(:let, [:show, disable: true]),
        _S << E(:e, 'package') << E(:any) << E(:e, ';') << A(:let, [:show, disable: true])
      )
    }
  }
end

core.config_ast('message.parser') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:e, 'optional') << E(:any, repeat: 4) << E(:e, ';')\
                                << A(
                                  :let,
                                  action1
                                ),
        _S << E(:e, 'optional') << E(:any, repeat: 4) << E(:e, '[')\
                                << E(:any, repeat: 4) << E(:e, ';')\
                                << A(
                                  :let,
                                  action1
                                ),
        _S << E(:e, 'repeated') << E(:any, repeat: 4) << E(:e, ';')\
                                << A(
                                  :let,
                                  action1
                                ),
        _S << E(:e, 'repeated') << E(:any, repeat: 4) << E(:e, '[')\
                                << E(:any, repeat: 4) << E(:e, ';')\
                                << A(
                                  :let,
                                  action1
                                )
      )
    }
  }
end

core.config_ast('enum.parser') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:any, at_head: true) << E(:any, repeat: 2) << E(:e, ';')\
           << A(
             :let,
             action2
           )
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
           << A(:let, [:redirect, :_3, 2..-2, dry_run: dry2, namespace: :_2, ast_include: ['enum']])
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
