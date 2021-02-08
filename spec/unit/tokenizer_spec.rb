# rubocop:disable all
# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe SheepAst::Tokenizer do  # rubocop: disable all
  let(:basepath) { Dir.pwd }
  let(:ok_str) { [["a", " ", "b", " ", "c", " ", "d", "\n"], ["1", " ", "2", " ", "3", " ", "4", "\n"], ["123", " ", "456", "\n"], ["abc", " ", "def", "\n"], ["!", "\"", "#", "$", "%", "&", "'", "(", ")", "=", "~", "|", "\n"], ["`", "{", "+", "*", "}", "<", ">", "?", "_", "\n"]] } # rubocop:disable all
  let(:ok_str2) { [["a b", " ", "c", " ", "d", "\n"], ["1", " ", "2", " ", "3", " ", "4", "\n"], ["111", "456", "\n"], ["abc", " ", "def", "\n"], ["!", "\"", "#", "$", "%", "&", "'", "(", ")", "=", "~", "|", "\n"], ["`", "{+*", "}", "<>", "?", "_", "\n"]] } # rubocop: disable all
  let(:tok) { SheepAst::Tokenizer.new }
  it 'can tokenize' do
    buf, max_line = tok.tokenize(basepath + '/spec/unit/test_files/test3.txt')
    expect(buf).to eq(ok_str)
    expect(max_line).to eq(6)
  end

  it 'can tokenize2' do
    _buf, max_line = tok.tokenize(basepath + '/spec/unit/test_files/test4.txt')
    expect(max_line).to eq(1)
  end

  it 'can tokenize3' do
    str =
'a b c d
1 2 3 4
123 456
abc def
!"#$%&\'()=~|
`{+*}<>?_
'
    buf, max_line = tok << str
    expect(buf).to eq(ok_str)
    expect(max_line).to eq(6)
  end

  it 'can tokenize3' do
    tok.add_token tok.cmp('Hello',' ', 'world', '!')
    buf, _max_line = tok << 'Hello world!'
    expect(buf).to eq([['Hello world!']])
  end

  it 'can use tokenizer_rules' do
    tok.add_token tok.cmp('{', '+')
    tok.add_token tok.cmp('<', '>')
    tok.add_token tok.cmp('a', ' ', 'b')
    tok.add_token tok.cmp('123', ' '), '111'
    tok.add_token tok.cmp('{+', '*')
    buf, max_line = tok.tokenize(basepath + '/spec/unit/test_files/test3.txt')
    expect(buf).to eq(ok_str2)
    expect(max_line).to eq(6)
  end

  it 'can use regexp for ip address' do
    oneto255 = /^[1-2][0-5]?[0-5]?$/
    tok.add_token tok.cmp(oneto255, '.', oneto255, '.', oneto255, '.', oneto255)
    buf, max_line = tok << '10.10.244.2/32'
    expect(buf[0][0]).to eq('10.10.244.2')
    expect(max_line).to eq(1)
  end
  it 'can use regexp for ip address. Fail for regex' do
    oneto255 = /^[1-2][0-5]?[0-5]?$/
    tok.add_token tok.cmp(oneto255, '.', oneto255, '.', oneto255, '.', oneto255)
    buf, max_line = tok << '10.10.300.2/32'
    expect(buf[0][0]).to eq('10')
    expect(max_line).to eq(1)
    tok.dump(:ldebug)
  end
  it 'can use regexp for ip address by recursive option' do
    oneto255 = /^[1-2][0-5]?[0-5]?$/
    tok.add_token tok.cmb(oneto255, '.')
    tok.add_token tok.cmb(/.*\./, /.*\./), recursive: true
    tok.add_token tok.cmb(/.*\./, oneto255)
    _buf, _max_line = tok << '10.10.200.2/32'
    tok.dump(:ldebug)
  end
  it 'can use split rule' do
    tok.use_split_rule { tok.split_space_only }
    buf, _max_line = tok << 'abc.a.a. 10.10.200.2/32'
    expect(buf).to eq([['abc.a.a.', '10.10.200.2/32']])
  end
  it 'can use split rule2' do
    buf, _max_line = tok << 'Hello, world. Now 2020/12/14 1:43'
    # p buf
    tok.use_split_rule { tok.split_space_only }
    buf, _max_line = tok << 'Hello, world. Now 2020/12/14 1:43'
    # p buf
  end
  it 'can use split rule2' do
    buf, _max_line = tok << 'Hello, world. Now 2020/12/14 1:43'
    # p buf
    tok.use_split_rule { tok.split_space_only }
    buf, _max_line = tok << "Hello, world. Now 2020/12/14 1:43 \n Hello again"
    expect(buf).to eq([["Hello,", "world.", "Now", "2020/12/14", "1:43", "\n"], ["Hello", "again"]])
    # p buf
  end
end
