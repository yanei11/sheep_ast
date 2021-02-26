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
    register_syntax(
      'analyze',
      A(:let, [:grep], [:show, disable: true], [:debug, disable: true])
    ) {
      SS(
        S() << E(:encr, input_expr, "\n")
      )
    }
  }

  core.let.within {
    def grep(pair, datastore, **options)
      data = pair[:_data]
      str = "#{data.file_info.file}:".blue
      str += data.raw_line.chop.to_s
      puts str
    end
  }
end

core.report(raise: false) {
  core.analyze_file(input_files)
}
