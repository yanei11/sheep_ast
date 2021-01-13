# API spec

In this file, external interface for sheep_ast user is written.
Listed APIs are currenly supported.

# Command line option

sheep_ast has following command line option:

```
-E [Array] Specify directories for the files that should not be included
-I [Array] Specify directories for the include files
-d Dump Debug information'
```

# Environment Variable

sheep_ast has following environment parameter.

## SHEEP_LOG

If it is set DEBUG, emit ldebug result for debugging.

## SHEEP_LET_DISABLE_DEBUG

If this is defined, pry debug session in let's :debug fuction will be always disabled.

# Class, Module

Following class and module are the objects that holds external APIs.
In sheep_ast document, for the maintainablity, usage will be written in the source code comments.
The external API is the function marked as `public`.
`private` functions are not intended to expose to the user.
Please refer to the comments of public method for external APIs.

Note taht the `public` and `private` tags are added by Yard framework.

Please also refer to the {file.Framework.html} for the Framework design.
It helps why followings are the exposed objects.

## AnalyzerCore

see {SheepAst::AnalyzerCore}

## Tokenizer

see {SheepAst::Tokenizer}

## Syntax

see {SheepAst::Syntax}

## SyntaxAlias

see {SheepAst::SyntaxAlias}

## Match

The supported Match like ExactMatch is created from MatchFactory object.
The creation of the Match is aggregated to the following MatchFactory Methods.
Please refer to the `new` methods of Match Objects from `View source` tab for the kind and usage of Matches.

see {SheepAst::MatchFactory#initialize}

User uses Match like:

```
E(:e, 'test') # ;e indicates ExactMatch
```

And the this `:e` Symbol and Object mapping is shown in {SheepAst::MatchFactory#gen}

## Action

The supported Action like Let is created from ActionFactory object.
The creation of the Action is aggregated to the following ActionFactory Methods.
Please refer to the `new` methods of Action Objects from `View source` tab for the kind and usage of Aitions.

see {SheepAst::ActionFactory#initialize}

User uses Action like:

```
A(:let, ..) # ;e indicates Let Action
```

And the this `:let` Symbol and Object mapping is shown in {SheepAst::ActionFactory#gen}

### Let

Let object has some included module, to extend features in the Let object.
To include modules, Let object can get features like, to record matched strings, to recursive evaluation of matched strings, to include another files, etc.
Please see included module from {SheepAst::Let}

