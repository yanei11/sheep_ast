# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'match/exact_match'

describe SheepAst::ExactMatch do
  let(:em) { SheepAst::ExactMatch.new }
  it 'can be created' do
    em.init
  end
  it 'can be created' do
    t_em = em.new(')', :test)
    expect(t_em.store_sym).to eq(:test)
    t_em.node_id = 1
    t_em.my_id = 2
    expect(t_em.key).to eq(')')
    expect(t_em.node_info.node_id).to eq(1)
    expect(t_em.node_info.match_id).to eq(2)
    data = SheepAst::AnalyzeData.new
    data.expr = ')'
    t_em.matched(data)
    expect(t_em.matched_expr).to eq(')')
    # t_em.matched_end(data)
  end
end
