# typed: false
# rubocop: disable all
# frozen_string_literal: true



require 'spec_helper'
require 'sheep_ast'

describe SheepAst::CyclicList do
  it 'can hold history less than limit' do
    list = SheepAst::CyclicList.new(5)
    count = 0
    3.times do
      count += 1
      list.put(count)
    end

    expect(list.history(0)).to eq(3)
    expect(list.history(1)).to eq(2)
    expect(list.history(2)).to eq(1)
  end
  it 'can hold history more than limit' do
    list = SheepAst::CyclicList.new(5)
    count = 0
    10.times do
      count += 1
      list.put(count)
    end

    expect(list.history(0)).to eq(10)
    expect(list.history(1)).to eq(9)
    expect(list.history(2)).to eq(8)
  end
  it 'return nil if out of range' do
    list = SheepAst::CyclicList.new(5)
    count = 0
    10.times do
      count += 1
      list.put(count)
    end

    expect(list.history(6)).to eq(nil)
  end
  it 'can get last' do
    list = SheepAst::CyclicList.new(5)
    count = 0
    10.times do
      count += 1
      list.put(count)
    end

    expect(list.last).to eq(10)
  end
end
