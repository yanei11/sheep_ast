#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe 'revert ast' do
  let(:core) { SheepAst::AnalyzerCore.new }
  it 'can shows next command' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          _SS(
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
          _SS(
            _S << E(:e, 'f') << E(:e, 'g', description: 'test') << E(:e, 'h') << E(:e, 'i'),
            _S << E(:e, 'f') << E(:e, 'g') << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      command =  core.next_command('default.test2')
      core << "f"
      command =  core.next_command('default.test2')
      core << "g h"
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('i')
    }.not_to raise_error
  end


  it 'can shows next command after move up' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          _SS(
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
          _SS(
            _S << E(:e, 'f') << E(:e, 'g',  description: 'test') << E(:e, 'h') << E(:e, 'i'),
            _S << E(:e, 'f') << E(:e, 'g') << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core << "f"
      core << "g h"
      core.move_node('default.test2', SheepAst::NodeOperation::Direction::Up)
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('h')
      expect(command[1].command).to eq('1')
      core << "h"
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('i')
    }.not_to raise_error
  end

  it 'can shows next command after move top' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          _SS(
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
          _SS(
            _S << E(:e, 'f') << E(:e, 'g',  description: 'test') << E(:e, 'h') << E(:e, 'i'),
            _S << E(:e, 'f') << E(:e, 'g') << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core << "f"
      core << "g h"
      core.move_node('default.test2', SheepAst::NodeOperation::Direction::Top)
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('f')
    }.not_to raise_error
  end

  it 'can shows next command after commited and revert' do
    core.config_ast('default.test') do |ast, syn|
      syn.within {
        register_syntax('ignore', syn.A(:na)) {
          _SS(
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
          _SS(
            _S << E(:e, 'f') << E(:e, 'g',  description: 'test') << E(:e, 'h') << E(:e, 'i'),
            _S << E(:e, 'f') << E(:e, 'g') << E(:e, '1') << E(:e, '2')
          )
        }
      }
    end
    expect {
      core << "f"
      core << "g"
      core.move_node('default.test2', SheepAst::NodeOperation::Direction::Commit)
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('h')
      core << "h"
      core.move_node('default.test2', SheepAst::NodeOperation::Direction::Revert)
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('h')
      core.move_node('default.test2', SheepAst::NodeOperation::Direction::Top)
      core.move_node('default.test2', SheepAst::NodeOperation::Direction::Commit)
      command = core.next_command('default.test2')
      expect(command[0].command).to eq('f')
    }.not_to raise_error
  end
end
