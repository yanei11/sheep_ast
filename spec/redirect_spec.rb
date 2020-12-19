# rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'analyzer_core'
require 'action/qualifier'

describe SheepAst::Let do
  let(:core) { SheepAst::AnalyzerCore.new }

  it 'redirect matched expression and extract the line' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze') {
          _SS(
           _S << E(:e, 'this') \
              << E(:e, 'is') \
              << A(:let,
                   [:redirect,
                    redirect_line_matched: true,
                    dry_run: false,
                    debug: false,
                    ast_include: 'redirect'
                   ]
                  )
          )
        }
      }
    end

    core.config_ast('redirect.main') do |ast, syn|
      syn.within {
        register_syntax('analyze') {
          _SS(
           _S << E(:e, 'a') \
              << E(:e, 'b') \
              << E(:e, 'c') \
              << A(:let,
                   [:show, disable: true]
                  )
          )
        }
      }
    end


    core.config_ast('always.ignore2') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:let, [:show, disable: true])) {
          _SS(
             _S << E(:any)
          )
        }
      }
    end

    expect {
      core.analyze_file(['spec/test_files/test2.txt'])
    }.not_to raise_error
  end

  it 'redirect matched expression and extract multiple line' do
    core.config_tok do |tok|
      tok.use_split_rule { tok.split_space_only }
    end

    core.config_ast('default.main') do |ast, syn|
      syn.within {
        register_syntax('analyze') {
          _SS(
           _S << E(:enc, 'a', 'test') \
              << A(:let,
                   [:show, disable: true],
                   [:redirect,
                    redirect_line_matched: true,
                    dry_run: false,
                    debug: false,
                    ast_include: 'redirect'
                   ]
                  )
          )
        }
      }
    end

    core.config_ast('redirect.main') do |ast, syn|
      syn.within {
        register_syntax('analyze') {
          _SS(
           _S << E(:e, 'a') \
              << E(:e, 'b') \
              << E(:e, 'c') \
              << A(:let,
                   [:show, disable: true]
                  )
          )
        }
      }
    end


    core.config_ast('always.ignore2') do |ast, syn|
      syn.within {
        register_syntax('ignore', A(:let, [:show, disable: true])) {
          _SS(
             _S << E(:any)
          )
        }
      }
    end

    expect {
      core.report(raise: true) {
        core.analyze_file(['spec/test_files/test2.txt'])
      }
    }.not_to raise_error
  end

end
