#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::IndexCondition do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can match multiple condition' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:let, [:record, :test, :_1])) {
        syn._S << syn.E(:e, 'a', index_cond: syn.idx('i', 'j', offset: 5))
      }
    end

    core.config_ast('always.ignore') do |ast, syn, mf, af|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          syn._SS(
            syn._S << syn.E(:any)
         )
       }
      }
    end

    expect {
      core.report(raise: true ) {
      core << "a b c d
               a b c d 
               i j k"
      core << '__sheep_eof__'
    }
    }.not_to raise_error
    expect( core.data_store.value(:test) ).to eq('a')
  end
  it 'can match multiple condition by multiple index match' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:let, [:record, :test, :_1])) {
        syn._S << syn.E(:e, 'a', index_cond: [syn.idx('b', offset: 1), syn.idx('k', offset: 7)])
      }
    end

    core.config_ast('always.ignore') do |ast, syn, mf, af|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          syn._SS(
            syn._S << syn.E(:any)
         )
       }
      }
    end

    expect {
      core.report(raise: true ) {
      core << "a b c d
               a b c d 
               i j k"
      core << '__sheep_eof__'
    }
    }.not_to raise_error
    expect( core.data_store.value(:test) ).to eq('a')
  end

  it 'can match multiple condition with offset_line' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:let, [:record, :test, :_1])) {
        syn._S << syn.E(:e, 'a', index_cond: syn.idx('i', 'j', line_offset: 1, offset: 1))
      }
    end

    core.config_ast('always.ignore') do |ast, syn, mf, af|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          syn._SS(
            syn._S << syn.E(:any)
         )
       }
      }
    end

    expect {
      core.report(raise: true ) {
      core << "a b c d
               a b c d 
               i j k"
      core << '__sheep_eof__'
    }
    }.not_to raise_error
    expect( core.data_store.value(:test) ).to eq('a')
  end
  it 'can match multiple condition by multiple index match' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register_syntax('match', syn.A(:let, [:record, :test, :_1])) {
        syn._S << syn.E(:e, 'a', index_cond: [syn.idx('i', line_offset: 1, offset: 1), syn.idx('k', line_offset: 1 ,offset: 3)])
      }
    end

    core.config_ast('always.ignore') do |ast, syn, mf, af|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          syn._SS(
            syn._S << syn.E(:any)
         )
       }
      }
    end

    expect {
      core.report(raise: true ) {
      core << "a b c d
               a b c d 
               i j k"
      core << '__sheep_eof__'
    }
    }.not_to raise_error
    expect( core.data_store.value(:test) ).to eq('a')
  end
end
