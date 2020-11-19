#rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'analyzer_core'
require 'messages'
require 'syntax'

describe Sheep::AnalyzerCore do # rubocop: disable all
  let(:core) { Sheep::AnalyzerCore.new }
  it 'can be ceated' do
    ast = core.config_ast('default.test') do |_ast, _syn, _mf, _af|; end
    expect(core.from_id(ast.my_id).object_id).to eq(
      core.from_name('default.test').object_id
    )
  end
  it 'can be created and add some matches' do # rubocop: disable all
    core.config_ast('default.test') do |ast, syn, mf, af|
      matches = []
      mf.within do
        matches << gen(:e, 'c', :test)
      end
      action = af.gen(:na)
      ast.add(matches, action, 'test')
    end

    core.config_ast('default.test') do |ast, syn, mf, af|
      matches = []
      mf.within do
        matches << gen(:e, 'f', :test) << gen(:e, 'd', :test2) <<
          gen(:e, 'e', :test3) << gen(:e, 'f', :test4)
      end
      action = af.gen(:na)
      ast.add(matches, action, 'test2')
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      matches = [
        [:e, 'f'], [:e, 'd'], [:r, '.*']
      ].map { |arg| mf.gen(*arg) }
      action = af.gen(:na)
      ast.add(matches, action, 'test2')
    end

    core.config_ast('default.test3') do |ast, syn, mf, af|
      syn.register_array('default.test') { [[:e, 'f'], [:e, 'd'], [:r, '.*'], [:na]] }
    end

    core.config_ast('default.test4') do |ast, syn, mf, af|
      syn.register_array_multi('default.test') {
        [
          [[:e, 'f'], [:e, 'd'], [:r, '.*'], [:na]],
          [[:e, 'a'], [:e, 'b'], [:r, '...'], [:r, '##a'], [:na]]
        ]
      }
    end

    core.config_ast('default.test5') do |ast, syn, mf, af|
      syn.register('default.test', af.gen(:na)) { [[:e, 'f'], [:e, 'd'], [:r, '.*']] }
    end

    core.config_ast('default.test6') do |ast, syn, mf, af|
      syn.register_multi('default.test', af.gen(:na)) {
        [
          [[:e, 'f'], [:e, 'd'], [:r, '.*']],
          [[:e, 'a'], [:e, 'b'], [:r, '...'], [:r, '##a']]
        ]
      }
    end

    core.config_ast('default.test7') do |ast, syn, mf, af|
      syn.register_multi('default.test', [af.gen(:na), af.gen(:na)]) {
        [
          [[:e, 'f'], [:e, 'd'], [:r, '.*']],
          [[:e, 'a'], [:e, 'b'], [:r, '...'], [:r, '##a']]
        ]
      }
    end
    core.dump(:pdebug)
  end

  it 'will raise exception when duplicated match' do
    core.config_ast('default.test7') do |ast, syn, mf, af|
      expect {
        syn.register_multi('default.test', [af.gen(:na), af.gen(:na)]) {
          [
            [[:e, 'f'], [:e, 'd'], [:r, '.*']],
            [[:e, 'f'], [:e, 'd'], [:r, '.*']]
          ]
        }
      }.to raise_error Sheep::Exception::ApplicationError
    end
  end

  it 'can parse file' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do 
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
          [[:e, 'f'], [:e, 'd'], [:e, 'aa'], [:e,'ddd']]
      }
    end
    core.dump(:pdebug)
    expect { core << "f d aa 
    ddd" }.not_to raise_error
  end

  it 'can parse file' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do 
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
          [[:e, 'f'], [:e, 'd'], [:e, 'aa'], [:e,'ddd']]
      }
    end
    core.dump(:pdebug)
    expect { core << "f d aa 
    ddd" }.not_to raise_error
  end

  it 'can catch exception' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do 
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
          [[:e, 'f'], [:e, 'd'], [:e, 'aa']]
      }
    end
    core.report(:ldebug) {
      core << "f d aa 
      ddd"
    }
  end
  it 'parse multiple expr' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do 
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
          [[:e, 'f'], [:e, 'd'], [:e, 'aa']]
      }
    end
    core.report(:ldebug) {
      core << "f d"
      core << "aa"
      core << "f d aa"
    }
  end
  it 'validation fail when eof' do
    core.config_ast('default.test1') do |ast, syn, mf, af|
      syn.register_multi('ignore', af.gen(:na)) {
        [
          [syn.space],
          [syn.crlf],
          [syn.lf],
          [syn.eof]
        ]
      }
      ast.within do
        def not_found(data, _node)
          linfo "'#{data.expr}' not found"
          return Sheep::MatchAction::Continue
        end
      end
    end

    core.config_ast('default.test2') do |ast, syn, mf, af|
      syn.register('match', af.gen(:na)) {
          [[:e, 'f'], [:e, 'd'], [:e, 'aa']]
      }
    end
    expect {
      core << "f d"
      core << "aa"
      core << "f d "
      core << "__sheep_eof__"
    }.to raise_error Sheep::Exception::ApplicationError
  end
end
