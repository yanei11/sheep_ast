#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe 's_syntax' do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can have root branch' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          SS(
            space,
            crlf,
            lf,
            eof
          )
        }
      }
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
        register_syntax('match', syn.A(:na)) {
          SS(
            S(:root) << E(:e, 'f') << E(:e, 'g', description: 'test') << E(:e, 'h') << E(:e, 'i'),
            S(:root) << E(:e, 'f') << E(:e, 'g') << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core << "f"
      core << "g h"
      command = core.focus_on('default.test2').next_command
      expect(command[0].command).to eq('i')
    }.not_to raise_error
  end

  it 'can have root branch by short expression' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          SS(
            space,
            crlf,
            lf,
            eof
          )
        }
      }
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
        register_syntax('match', syn.A(:na)) {
          SS(
            S() << E(:e, 'f') << E(:e, 'g', description: 'test') << E(:e, 'h') << E(:e, 'i'),
            S() << E(:e, 'f') << E(:e, 'g') << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core << "f"
      core << "g h"
      command = core.focus_on('default.test2').next_command
      expect(command[0].command).to eq('i')
    }.not_to raise_error
  end

  it 'can share branch' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          SS(
            space,
            crlf,
            lf,
            eof
          )
        }
      }
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
        register_syntax('match', syn.A(:na)) {
          S(:branch) { S() << E(:e, 'f') << E(:e, 'g', description: 'test') }
          SS(
            S(:branch) << E(:e, 'h') << E(:e, 'i'),
            S(:branch) << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core << "f"
      core << "g h"
      core.focus_on('default.test2')
      command = core.next_command
      expect(command[0].command).to eq('i')
    }.not_to raise_error
  end

  it 'can share branch, multiple times' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          SS(
            space,
            crlf,
            lf,
            eof
          )
        }
      }
    end
    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.within {
        register_syntax('match', syn.A(:na)) {
          S(:branch)  { S() << E(:e, 'f') << E(:e, 'g', description: 'test') }
          S(:branch2) { S() << E(:e, 'f') << E(:e, 'g', description: 'test') }
          SS(
            S(:branch) << E(:e, 'h') << S(:branch2) << E(:e, 'i'),
            S(:branch) << E(:e, 'h') << S(:branch2) << E(:e, '1') << E(:e, 'i'),
            S(:branch) << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core.report(raise: true) {
        core << "f"
        core << "g h"
        core << "f"
        core << "g"
        core.focus_on('default.test2')
        command = core.next_command
        expect(command[0].command).to eq('i')
      }
    }.not_to raise_error
  end

end
