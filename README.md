# sheep_ast

sheep_ast is a toolkit made by ruby for those who wants to use AST(abstract syntax tree) to some analysis. It can be used for parsing, code generating, analysing etc. sheep_ast aims to provide easily customizable user interface for using AST.
  
# Features
sheep_ast supports following feature:

- Tokenize  
  sheep_ast has customizable tokenizer. It can split sentence to a string and also it can combine it to another set of string (token).  
- Parsing  
  sheep_ast has stages. The each stage can assign AST. Parsing by multiple stage is possible like, ignoring pattern by 1st AST, and extract pattern by 2nd AST, ...
- Action  
  At the end of AST, some action can be assigned. e.g. to store AST result to some symbol, to compile AST result to another file, etc.  
  User can define customized methods to the Action class `Let`.  

# Resource

- Github repository

  https://github.com/yanei11/sheep_ast

- Yard page

  https://yanei11.github.io/sheep_ast/

- Example1(Quick start guide1)

  https://yanei11.github.io/sheep_ast/file.Example1.html
  
