# typed: ignore
# frozen_string_literal: true

require 'sheep_ast'
require 'rainbow/refinement'

using Rainbow

input_expr = ARGV[0]
input_files = ARGV[1..-1]

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
  tok.token_rule('#', 'include')
  tok.token_rule('/', '/')
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:grep], [:show, disable: true],
                                 [:debug, disable: true])) {
      SS(
        S() << E(:r, input_expr)
      )
    }
  }

  core.let.within {
    def grep(pair, datastore, **options)
      data = pair[:_data] # accessing kind of raw information
      match = line_matched(data)
      str = "#{data.file_info.file}:".blue
      str += match.flatten.join
      puts str.gsub('__sheep_eol__', '')
    end
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('continue', A(:na)) {
      SS(
        S() << any
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(input_files)
}
