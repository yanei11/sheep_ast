# typed: false
# frozen_string_literal: true

require 'sheep_ast'

RSpec.describe SheepAst do
  it 'has a version number' do
    expect(SheepAst::VERSION).not_to be nil
  end
end
