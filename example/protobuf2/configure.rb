# typed: ignore
# frozen_string_literal: true

#rubocop: disable all
def configure(core)
  template1 = 'template_message.erb'
  template2 = 'template_enum.erb'
  action1 = [:compile, template1, { dry_run: false }]
  action2 = [:compile, template2, { dry_run: false }]
  dry1 = false
  dry2 = false

  core.config_tok do |tok|
  end

  core.config_ast('always.ignore') do |_ast, syn|
    syn.within {
      register_syntax('analyze', A(:na)) {
        SS(
          S() << E(:e, ' ')
        )
      }
    }
  end

  core.config_ast('default.ignore_syntax') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        SS(
          S() << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2')\
              << E(:e, '"') << E(:e, ';') << A(:let, [:show, disable: true]),
          S() << E(:e, 'package') << E(:any) << E(:e, ';') << A(:let, [:show, disable: true])
        )
      }
    }
  end

  core.config_ast('message.parser') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        S(:branch1) { S() << E(:e, 'optional') << E(:any, repeat: 4) }
        S(:branch2) { S() << E(:e, 'repeated') << E(:any, repeat: 4) }
        SS(
          S(:branch1) << E(:e, ';') << A(:let, action1),
          S(:branch1) << E(:e, '[') << E(:any, repeat: 4) << E(:e, ';')\
                                    << A(:let, action1),
          S(:branch2) << E(:e, ';') << A(:let, action1),
          S(:branch2) << E(:e, '[') << E(:any, repeat: 4) << E(:e, ';')\
                                    << A(:let, action1)
        )
      }
    }
  end

  core.config_ast('enum.parser') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        SS(
          S() << E(:any, at_head: true) << E(:any, repeat: 2) << E(:e, ';')\
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
        SS(
          S() << E(:e, 'message') << E(:any) << E(:sc, '{', '}') \
              << A(:let, [:redirect, :_3, 2..-2, dry_run: dry1, namespace: :_2, ast_include: ['default', 'message']]),
          S() << E(:e, 'enum') << E(:any) << E(:sc, '{', '}') \
              << A(:let, [:redirect, :_3, 2..-2, dry_run: dry2, namespace: :_2, ast_include: ['enum']])
        )
      }
    }
  end

  core.config_ast('always.continue') do |_ast, syn|
    syn.within {
      register_syntax('analyze', A(:na)) {
        SS(
          S() << E(:e, "\n"),
          S() << E(:eof)
        )
      }
    }
  end
end
