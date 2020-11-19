# rubocop: disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'analyzer_core'
require 'messages'
require 'syntax'

describe Sheep::DataStore do
  let(:core) { Sheep::AnalyzerCore.new }
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
       syn.register(
         'match',
         af.gen(
           :let,
           [:fff, :a], [:fff, :b],
           [:record_kv_by_id, :test_H, :test5, :test1_A],
           [:record_kv_by_id, :test_H, :test6, :test1_A]
         )
       ) {
         [[:e, 'f', :test1_A], [:e, 'd', :test1_A], [:e, 'aa', :test3], [:e, 'ddd', :test4],
          [:r, '.*', :test6], [:r, '.*', :test5]]
       }
       syn.action.within {
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
