# typed: false
# frozen_string_literal: true

require './lib/analyzer_core'
require 'rainbow/refinement'

using Rainbow

input_expr = ARGV[0]
input_files = ARGV[1..-1]

core = Sheep::AnalyzerCore.new

core.config_tok do |tok|
  tok.add_token tok.cmp('#', 'include')
  tok.add_token tok.cmp('/', '/')
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:grep], [:show, { disable: true }], [:debug])) {
      _SS(
        _S << E(:encr, input_expr, "\n")
      )
    }
  }

  syn.action.within {
    def grep(key, datastore, **options)
      str = "#{@data.file_info.file}:".blue
      str += @data.raw_line.chop.to_s
      puts str
    end
  }
end

core.report(raise: false) {
  core.analyze_file(input_files)
}
