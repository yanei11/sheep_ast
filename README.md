# sheep_ast

sheep_ast is a toolkit made by ruby for those who wants to use Ast(abstract syntax tree) to some analysis. It can be used for parsing, code generating, analysis etc. sheep_ast aims to provide easily customizable user interface for using Ast.
  
# Feature
sheep_ast supports following feature:

- Tokenize  
  sheep_ast has customizable tokenizer. It can split sentence to a string and also it can combine it to another set of string (token).  
- Parsing  
  sheep_ast has stages. The each stage can assign Ast. Parsing by multiple stage is possible like, ignoring pattern by 1st Ast, and extract pattern by 2nd Ast and so on. sheep_ast has function to handle namespace.
- Action  
  At the end of Ast, some action can be assigned. e.g. to store Ast result to some symbol, to compile Ast result to another file, etc. User can define customized methods to the Action class `Let`.  

# Introduction

Using sheep_ast, user can do pattern matching and extract data very easy like following:

```ruby
# typed: false
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
```

And the result will be

```
Input string is Hello sheep_ast World
Extracted result is following:
{"Hello"=>"sheep_ast"}
```

So, from the `Hello sheep_ast World` string, we can extract `Hello` and `sheep_ast`.  

As well as above basic Match - Action function, sheep_ast has following functions for further parsing, code genarating, analysis.

- Compile  
  Using sheep_ast and erb, user can generate file from the extracted keywords.
  Please see example3 for detail

- Recursive estimate  
  sheep_ast supports recursive estimation of matched strings by let_redirect module.  
  So, user can have more well readable, easy to use the Ast.

- Including another file  
  Using let_include module, sheep_ast can analyze another file.  
  The example is `#include "xxx.hh"` for cpp language, sheep_ast searh xxx.hh from given paths when it is included.


# Getting Started
Please clone this repository or install via gem. Following commands from top directory runs testcode and examples.

- rake  
  This command runs rspec. The rspec code has more examples

- rake example1, rake exampe2, ...  
  This command runs examples introduced below.
  
The example explanation is in the below Resources section.

# Executables

sheep_ast supports script file, and appimage executables as well as above library use.

## script

sheep_ast also supports executable format script. It is `run-sheep-ast` and it is under the bin/ directory.  
Executing with `-h` option shows help.  
  
The example to use this executable is to execute following commands from the top of repository:  

```
bin/run-sheep-ast -r example/protobuf2/configure.rb -o example/protobuf2/ -t example/protobuf2/ example/protobuf2/example.proto 
```

This produce same output for Example3. Please see the example files in the command.  

## Appimage

sheep_ast releases Appimage format here https://github.com/yanei11/sheep_ast/releases.  
So, you can run only download this file and execute it, but unfortunately, for this repository's appimage has limitation that the file can't accept relative path.  
So, it is needed to specify absolute path. i.e. following command is needed to get above same result.

```
./run-sheep-ast-0.4.1.glibc2.3-x86_64.AppImage -r $PWD/example/protobuf2/configure.rb -o $PWD/example/protobuf2 -t $PWD/example/protobuf2/ $PWD/example/protobuf2/example.proto
```

# Resources
- Yard page  
  https://yanei11.github.io/sheep_ast_pages/

- Github repository  
  https://github.com/yanei11/sheep_ast

- Example1 (grep like application)  
  https://yanei11.github.io/sheep_ast_pages/file.Example1.html
  
- Example2 (Keyword extraction from cpp file)  
  https://yanei11.github.io/sheep_ast_pages/file.Example2.html

- Example3 (generate file (compile) from proto file)  
  https://yanei11.github.io/sheep_ast_pages/file.Example3.html

- API document  
  https://yanei11.github.io/sheep_ast_pages/file.API.html

- Framework Design  
  https://yanei11.github.io/sheep_ast_pages/file.Framework.html

- Change Log  
  https://yanei11.github.io/sheep_ast_pages/file.CHANGELOG.html
