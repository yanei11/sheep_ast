# Introduction

This page explains sheep_ast framework design.  

# Design policy

Several policies are existed.

- Not to use global variable. For this purpose, factory pattern is applied for the entity that needs multiple creation.

- Externl interface tries to be aggregated to AnalyzerCore object.
 
- Tries to finish in one file for the user modification part.

# Architecture

The Overall Architeture of the sheep_ast is below. Objects that external API holds are Marked underline.
To see the diagram, you'll find that AnalyzerCore object holds everything and some objects are generated from Factory object.

Here `->` describes creation, and `-` describes reference relationship. 


```
AnalyzerCore
-------------
  |
  |->Tokenizer
  | ---------- 
  |
  |->Syntax - SyntaxAlias
  | -------   ------------
  |
  |--------------------------------------------------------------------------------------
  |                                                                                     |
  |-> FileManager                                                                       |
  |-> StageManager -> AstManager -> NodeFactory -> Node                                 |
                      ----------                    |                                   |/
                                                    |- XXXMatch  <- MatchFactory  <-|- FoF
                                                    |  --------                     |
                                                    |    |- ExactMatch              |
                                                    |    |- RegexMatch              |
                                                    |    |- ...                     |
                                                    |                               |
                                                    |- XXXAction <- ActionFactory <-|
                                                       ---------
                                                         |- NoAction
                                                         |- Let
                                                              |- LetRedirect
                                                              |- LetReord
                                                              |- LetCompile
                                                              |- ...
```

Followings are the information flow.

```

Strings: Hello, world
|
|/
Tokenizer
|
|  expr = ['Hello', ',', 'world']
|/
FileManager
|
|  Processing with each tokenized data
|  AnalyzeData object: data <- 'Hello'
|/
StageManager
|
| For each Stage, it analyze data
|
|/
Node
|
|  find_nex_node by testing each match
|/
Match
|
| If the Match is the last one, calls Action
|
Action <- data
|
|
|    Get Next expression.
|
|   |\
 ---
```

You can trace flow by enabling log level of SHEEP_LOG environment variable like SHEEP_LOG=DEBUG.

Sheep_ast has more function than just Match - Action.  
Followings are highlight features provided by Framework.

# Redirect and Namespace

In {SheepAst::Let Let} object, there is redirect function.

This function allows user to recursively estimate matched strings to selected Ast. In other words, it redirect matched expression to selected Ast. This is why the function is named redirect.

With option of redirect function, it is possible to put namespace. It is also possible to redirect multiple times.

# Compile

In {SheepAst::Let Let} object, there is compile function.

With the function, it is possible to generate new file from matched data and template file. The template file is erb format. Please see Example3 for the usage.

# DataStore

In {SheepAst::Let Let} object, there is record function.

This function allow user to record specified string. This function uses {SheepAst::DataStore DataStore} object. Please see the yard page for the usage.

# Include Handler

In {SheepAst::Let Let} object, there is include function.

This function allows user to switch to analyze another file. For example, if there is `#include "xxx.hh"` strings while parsing, framework provides way to switch to analyze xxx.hh from the given paths.
