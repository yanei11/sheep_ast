# rubocop: disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

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
           [:record, :test_H, :test5, :test1_A],
           [:record, :test_H, :test6, :test1_A],
           [:record, :test, :test1_A],
           [:record, :test_A, :test1_A],
           [:record, :test_A, :test1_A]
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
     expect(core.data_store.search(:test_H).data['d']).to eq ['f', 'd']
   end
   it 'can store hash in hash' do
     ds = SheepAst::DataStore.new
     ds.assign(:example_HHL).keeplast('a1', 'b1', 'c1')
     ds.assign(:example_HHL).keeplast('a2', 'b2', 'c2')
     expect(ds.assign(:example_HHL).find('a1', 'b1')).to eq('c1')
     expect(ds.assign(:example_HHL).find('a2', 'b2')).to eq('c2')
     ds.assign(:example_HHL).keeplast('a1', 'b1', 'c3')
     expect(ds.assign(:example_HHL).find('a1', 'b1')).to eq('c3')
   end
   it 'can store hash in hash with StoreElement' do
     ds = SheepAst::DataStore.new
     se = SheepAst::StoreElement.new(1, {'test1' => 1, 'test2' => '2'})
     ds.assign(:example_HHL).keeplast('a1', 'b1', se)
     expect(ds.assign(:example_HHL).find('a1', 'b1').data).to eq 1
     expect(ds.assign(:example_HHL).find('a1', 'b1').meta('test1')).to eq 1
     expect(ds.assign(:example_HHL).find('a1', 'b1').meta('test2')).to eq '2'
     ds.value(:example_HHL).remove
     expect(ds.value(:example_HHL).data).to eq({})
   end
end
