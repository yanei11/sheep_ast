# typed:ignore
# frozen_string_literal: true

require 'sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
  tok.use_split_rule { tok.split_space_only }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:e, 'Hello') << E(:any) << E(:e, 'World') <<
           A(:let, [:record, :test_H, :_1, :_2])
      )
    }
  }
end

input = 'Hello sheep_ast World'

core.report(raise: false) {
  core << input
}

puts "Input string is #{input}"
puts 'Extracted result is following:'
p core.data_store.value(:test_H)
