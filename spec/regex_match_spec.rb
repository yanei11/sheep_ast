# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'match/regex_match'

describe Sheep::RegexMatch do
  let(:rm) { Sheep::RegexMatch.new }
  it 'can be created' do
    rm.init
  end
  it 'can use regex match' do
    t_rm = rm.new('abc..', :test)
    expect(t_rm.store_sym).to eq(:test)
    t_rm.node_id = 1
    t_rm.my_id = 2
    expect(t_rm.key).to eq('abc..')
    expect(t_rm.node_info.node_id).to eq(1)
    expect(t_rm.node_info.match_id).to eq(2)
    data = Sheep::AnalyzeData.new
    data.expr = 'abcde'
    t_rm.match(data)
    t_rm.matched(data)
    # t_rm.matched_end(data)
    expect(t_rm.matched_expr).to eq('abcde')
  end
end
