# typed: false
# frozen_string_literal: true
# rubocop: disable all

require 'sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
  tok.add_token tok.cmp('#', 'include')
  tok.add_token tok.cmp('/', '/')
end

core.sheep_dir_path_set(['spec/test_files/'])

core.config_ast('always.ignore') do |ast, syn|
  syn.within {
    register_syntax('ignore', A(:na)) {
      _SS(
        _S << E(:e, ' '),
        _S << E(:e, "\n"),
        _S << E(:eof)
      )
    }
  }
end

core.config_ast('default.main') do |ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:e, '#include') << E(:enc, '<', '>') << A(:let, [:include, :_2]),
        _S << E(:e, '#include') << E(:enc, '"', '"') << A(:let, [:include, :_2]),
        _S << E(:e, 'struct') << E(:any) << E(:sc, '{', '}') << E(:e, ';') << A(:let,
                                                                                [:show, {disable: true}],
                                                                                [:record, :test_H, :_2, :_3]
                                                                               )
      )
    }
  }
end

core.config_ast('always.ignore2') do |ast, syn|
  syn.within {
    register_syntax('ignore', A(:na)) {
      _SS(
        _S << E(:e, 'int') << E(:e, 'main') << E(:sc, '(', ')') << E(:sc, '{', '}')
      )
    }
  }
end

res = core.report(raise: false) { core.analyze_file(['spec/test_files/test1.cc']) }
expect(res).to be true
expect(core.data_store.value(:test_H)['Test1']).to eq(["{", "int", "a", ";", "int", "b", ";", "int", "c", ";", "}"])
expect(core.data_store.value(:test_H)['Test2']).to eq(["{", "int", "i", ";", "int", "j", ";", "int", "k", ";", "}"])
expect(core.data_store.value(:test_H)['Test3']).to eq(["{", "int", "x", ";", "int", "y", ";", "int", "z", ";", "}"])
