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

# Resource
- Yard page   
  https://yanei11.github.io/sheep_ast/

- Github repository  
  https://github.com/yanei11/sheep_ast

- Example1(Quick start guide1)  
  https://yanei11.github.io/sheep_ast/file.Example1.html
  
- Example2(Quick start guide2)  
  https://yanei11.github.io/sheep_ast/file.Example2.html
