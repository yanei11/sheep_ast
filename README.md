# sheep_ast

sheep_ast is a toolkit made by ruby for those who wants to use Ast(abstract syntax tree) to some analysis. It can be used for parsing, code generating, analysing etc. sheep_ast aims to provide easily customizable user interface for using Ast.
  
# Features
sheep_ast supports following feature:

- Tokenize  
  sheep_ast has customizable tokenizer. It can split sentence to a string and also it can combine it to another set of string (token).  
- Parsing  
  sheep_ast has stages. The each stage can assign Ast. Parsing by multiple stage is possible like, ignoring pattern by 1st Ast, and extract pattern by 2nd Ast and so on. sheep_ast has function to handle namespace.
- Action  
  At the end of Ast, some action can be assigned. e.g. to store Ast result to some symbol, to compile Ast result to another file, etc. User can define customized methods to the Action class `Let`.  

# Introduction

Using sheep_ast, user can do pattern matching and extract data very easy like following:

```
# typed: false
# frozen_string_literal: true

require './lib/analyzer_core'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
  tok.use_split_rule { tok.split_space_only }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      _SS(
        _S << E(:e, 'Hello') << E(:r, '.*') << E(:e, 'World') <<
           A(:let, [:record_kv_by_id, :test_H, :_1, :_2])
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
```

And the result will be

```
Input string is Hello sheep_ast World
Extracted result is following:
{"Hello"=>"sheep_ast"}
```

So, from the `Hello sheep_ast World` string, we can extract `Hello` and `sheep_ast`.


# Resources
- Yard page   
  https://yanei11.github.io/sheep_ast_pages/

- Github repository  
  https://github.com/yanei11/sheep_ast

- Example1(Quick start guide1)  
  https://yanei11.github.io/sheep_ast_pages/file.Example1.html
  
- Example2(Quick start guide2)  
  https://yanei11.github.io/sheep_ast_pages/file.Example2.html

- API  
  https://yanei11.github.io/sheep_ast_pages/file.API.html
