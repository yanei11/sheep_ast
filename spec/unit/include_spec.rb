# typed: false
# frozen_string_literal: true
# rubocop: disable all

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::LetInclude do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'handle include files' do
    core.config_tok do |tok|
      tok.add_token tok.cmp('#', 'include')
      tok.add_token tok.cmp('/', '/')
    end
 
    core.sheep_dir_path_set(['spec/unit/test_files/'])
    core.sheep_exclude_dir_path_set(['spec/unit/test_files/exclude'])

    core.config_ast('always.ignore') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:na)) {
          _SS(
            _S << E(:e, ' '),
            _S << E(:e, "\n"),
            _S << E(:eolcf)
          )
        }
      }
    end
  
    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze') {
          _SS(
            _S << E(:e, '#include') << E(:enc, '<', '>') << A(:let, [:include, :_2, skip_not_found: true]),
            _S << E(:e, '#include') << E(:enc, '"', '"') << A(:let, [:include, :_2, skip_not_found: true]),
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
  
    res = core.report(raise: false) { core.analyze_file(['spec/unit/test_files/test1.cc']) }
    expect(res).to be true
    expect(core.data_store.value(:test_H).data['Test1']).to eq(["{", "int", "a", ";", "int", "b", ";", "int", "c", ";", "}"])
    expect(core.data_store.value(:test_H).data['Test2']).to eq(["{", "int", "i", ";", "int", "j", ";", "int", "k", ";", "}"])
    expect(core.data_store.value(:test_H).data['Test3']).to eq(["{", "int", "x", ";", "int", "y", ";", "int", "z", ";", "}"])
    expect(core.data_store.value(:test_H).data['Test5']).to eq(["{", "int", "i", ";", "int", "j", ";", "int", "k", ";", "}"])
  end
end
