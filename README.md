# sheep_ast

sheep_ast is a toolkit made by ruby for those who wants to use Ast(abstract syntax tree) to some analysis. It can be used for parsing, code generating, analysis etc. sheep_ast aims to provide easily customizable user interface for using Ast.
  
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

# Feature
sheep_ast supports following features.  
The framework desin, and pipeline for the input data is written in the doc [here](https://yanei11.github.io/sheep_ast_pages/file.Framework.html). 

- Tokenize  
  sheep_ast has customizable tokenizer. It can split sentence to a string and also it can combine it to another set of string (token).  
- Parsing  
  sheep_ast has stages. The each stage can assign Ast. Parsing by multiple stage is possible like, ignoring pattern by 1st Ast, and extract pattern by 2nd Ast and so on. sheep_ast has function to handle namespace.
- Action  
  At the end of Ast, some action can be assigned. e.g. to store Ast result to some symbol, to compile Ast result to another file, etc. User can define customized methods to the Action class `Let`.  

As well as above basic Tokenize - Parse - Action function, sheep_ast has following functions for further parsing and code genarating.

- Compile  
  Using sheep_ast and erb, user can generate file from the extracted keywords.
  Please see [Example3](https://yanei11.github.io/sheep_ast_pages/file.Example3.html).

- Recursive estimate  
  sheep_ast supports recursive estimation of matched strings by let_redirect module.  
  So, user can have more well readable, easy to use the Ast.
  Please see [Example2](https://yanei11.github.io/sheep_ast_pages/file.Example2.html) and [Example3](https://yanei11.github.io/sheep_ast_pages/file.Example3.html).

- Including another file  
  Using let_include module, sheep_ast can analyze another file.  
  The example is `#include "xxx.hh"` for cpp language, sheep_ast searh xxx.hh from given paths when it is included.

# Getting Started  
  
Please see following Examples at Resources section below for the documentation.
  
To try sheep_ast, Please see the [INSTALL.md](https://github.com/yanei11/sheep_ast/blob/master/INSTALL.md) for the installation.  
sheep_ast supports [AppImage](https://appimage.org/) format as All in one package. You can download it and execute it for just using sheep_ast without installing ruby environment.   
(The AppImage contains ruby and just executing [bin/run-sheep-ast](https://github.com/yanei11/sheep_ast/blob/master/bin/run-sheep-ast) file)  
  
For further examples, you can try to clone this repository and `rake unit`, `rake bin` command may help you to try and see basic example.  
But this commands require to install ruby environement.

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

# Version

ruby 3.0.0 and ruby 2.7.2 are used for development
