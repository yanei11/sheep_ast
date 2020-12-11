# rubocop: disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'analyzer_core'
require 'messages'
require 'syntax'

describe SheepAst::DataStore do
  let(:core) { SheepAst::AnalyzerCore.new }
   it 'can parse file' do
     core.config_ast('default.test1') do |ast, syn, mf, af|
       syn.register_syntax('ignore', syn.A(:na)) {
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
           return SheepAst::MatchAction::Continue
         end
       end
     end

     core.config_ast('default.test2') do |ast, syn, mf, af|
       syn.within {
       register_syntax(
         'match',
         A(
           :let,
           [:fff, :a], [:fff, :b],
           [:record_kv_by_id, :test_H, :test5, :test1_A],
           [:record_kv_by_id, :test_H, :test6, :test1_A]
         )
       ) {
         _S << E(:e, 'f', :test1_A) << E(:e, 'd', :test1_A) << E(:e, 'aa', :test3) << E(:e, 'ddd', :test4) <<
               E(:r, '.*', :test6) << E(:r, '.*', :test5)
       }
       }
       core.let.within {
         def fff(key, datastore, test)
           ldebug key.inspect
           ldebug datastore.inspect
           ldebug @data.inspect
           ldebug @ret.inspect
           ldebug @node.inspect
           ldebug test.inspect
         end
       }
     end
     expect {
       core << "f d aa
     ddd c d"
     }.not_to raise_error
     expect(core.data_store.value(:test_H)['d']).to eq ['f', 'd']
   end
end
