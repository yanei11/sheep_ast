# Introduction

This page explains sheep_ast framework design.  

# Design policy

Several policy is existed.

- Not to use global variable. For this purpose, factory pattern is applied for the entity that needs multiple creation.

- Externl interface tries to be aggregated to AnalyzerCore object
  
# Architecture

The Overall Architeture of the sheep_ast is below. Objects that external API holds are Marked underline.

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
  |-------------------------------------------------------------------
  |                                                                  |
  |-> FileManager                                                    |
  |-> StageManager -> AstManager - Node <- NodeFactory               |
                      ----------   |                                 |/
                                   |- Match  <-  MatchFactory  <-|- FoF 
                                   |  -----                      |
                                   |    |-> ExactMatch           |
                                   |    |-> RegexMatch           |
                                   |    |-> ...                  |
                                   |                             |
                                   |- Action <-  ActionFactory <-|
                                      ------
                                        |-> NoAction
                                        |-> Let
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

# Redirect and Namespace

In {SheepAst::Let Let} object, there is redirect function.

This function allow user to recursively estimate matched expression with selected Ast. In other words, it redirect matched expression to selected Ast. With option of redirect function, it is possible to put namespace. It is also possible to redirect multiple times.

# DataStore

In {SheepAst::Let Let} object, there is record function.

This function allow user to record specified string. This function uses {SheepAst::DataStore DataStore} object. Please see the yard page for the usage.
