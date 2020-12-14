# rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'analyzer_core'
require 'action/qualifier'

describe SheepAst::Qualifier do
  it 'work' do
    qual = SheepAst::Qualifier.new(5, 'abc')
    data = SheepAst::AnalyzeData.new
    finfo = SheepAst::FileInfo.new
    data.file_info = finfo

    data.file_info.tokenized = [
      ['1','2','3'],
      ['4','5','6','7'],
      ['8'],
      ['abc'],
      ['10'],
      ['11','12','13','14']
    ]

    data.file_info.line = 1
    data.file_info.index = 1
    data.file_info.max_line = 6

    expect( qual.qualify(data) ).to eq(false)
  end

  let(:core) { SheepAst::AnalyzerCore.new }

  it 'validates fail at eof' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze') {
          _SS(
           _S << E(:e, 'a') << E(:e, 'b') << E(:e, 'c') << A(:na) << NEQ('d'),
           _S << E(:e, 'a') << E(:e, 'b') << E(:e, 'c') << E(:e, 'd') << E(:e, 'e') << A(:na)
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
      core.analyze_file(['spec/test_files/test1.txt'])
    }.not_to raise_error
  end
end
