# sheep_ast example3

In this example, it is tried to construct application from zero point.

This application makes list of gpb proto file's Structure and Members by extracting from proto file.  
The further application from this application is thought widely but this application is do just it.


# Skelton Application

At first, let's prepare skelton application. It shows following:

```
# typed: false
# frozen_string_literal: true

require './lib/sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

core.config_ast('default.main') do |_ast, syn|
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
```

If you execute this initial application, then it outputs like:

```
sheep_ast$ rake example3
echo "== Example3: compile =="
== Example3: compile ==
 bundle exec ruby example/protobuf/main.rb
F: StageManager> All the AST stage not found expression. Lazy Abort!
F: exception is observe. detail => #<SheepAst::Exception::NotFound: '"syntax"'>, bt => ["call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "stage_manager.rb:310", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:214", "file_manager.rb:71", "file_manager.rb:54", "file_manager.rb:54", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:213", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:134", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:15", "analyzer_core.rb:188", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:14"]
F:
F: ## Tokenizer information start ##
F:
F:
F: ## Analyze information start ##
F: Processing file
F: - example/protobuf/example.proto
F:
F: Tokenized Expression
F: - expr = syntax
F: - tokenized = ["syntax", " ", "=", " ", "\"", "proto2", "\"", ";", "\n"]
F: - line_num = 0
F: - index = 1
F: - max_line = 26
F:
F: |
F: |
F: |
F: |/
F: =================================
F: default.main> tree & Stack
F: =================================
F: [AST]
F: ---------------------------------
F: [Match Stack]
F: None
F: =================================
F: |
F: |
F: |
F: |
F: |  |\ Next Expression
F: |__|
F:
F: ## Resume Info ##
F: nil
F:
```

For this skelton application, the syntax `["syntax", " ", "=", " ", "\"", "proto2", "\"", ";", "\n"]` cannot be found by any Ast. That is why it raise NotFound exception.

# 1st Modification

Syntaxes for parsing should be registered to not raise NotFound Error.

```
# typed: false
# frozen_string_literal: true

require './lib/sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, ' ')
      )
    }
  }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show]) {
      _SS(
        _S << E(:e, 'syntax')
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
```

First try is that space should be ignored. So, space is entried in always.ignore Ast with NoAction. 
And 'syntax' string is entried in default.main Ast. It should match 'syntax' expression.  
Running application shows NotFound exception but not found '='.

```
sheep_ast$ rake example3
echo "== Example3: compile =="
== Example3: compile ==
 bundle exec ruby example/protobuf/main.rb
pair = {:_1=>"syntax", :_namespace=>[], :_raw_line=>"syntax = \"proto2\";\n", :_data=>custom inspect <SheepAst::AnalyzeData object_id = 5160, expr = '"syntax"', stack = [1], stack_symbol = [:_1], request_next_data = #<SheepAst::RequestNextData::Next>, file_info = custome inspect <SheepAst::FileInfo object_id = 5140, file = "example/protobuf/example.proto", chunk = nil, line = 0, max_line = 26, index = 1, namespace_stack = [], ast_include = nil, ast_exclude = nil, new_file_validation = true>, raw_line = "syntax = \"proto2\";\n"}
F: StageManager> All the AST stage not found expression. Lazy Abort!
F: exception is observe. detail => #<SheepAst::Exception::NotFound: '"="'>, bt => ["call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "stage_manager.rb:310", "call_validation.rb:847", "call_validation.rb:847", "analyzer_core.rb:214", "file_manager.rb:71", "file_manager.rb:54", "file_manager.rb:54", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:213", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:134", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:32", "analyzer_core.rb:188", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:31"]
F:
F: ## Tokenizer information start ##
F:
F:
F: ## Analyze information start ##
F: Processing file
F: - example/protobuf/example.proto
F:
F: Tokenized Expression
F: - expr = =
F: - tokenized = ["syntax", " ", "=", " ", "\"", "proto2", "\"", ";", "\n"]
F: - line_num = 0
F: - index = 3
F: - max_line = 26
F:
F: |
F: |
F: |
F: |/
F: =================================
F: always.ignore> tree & Stack
F: =================================
F: [AST]
F: (e)" "               -> NoAction [name: group(analyze)-1]
F: ---------------------------------
F: [Match Stack]
F: None
F: =================================
F: |
F: |
F: |
F: |/
F: =================================
F: default.main> tree & Stack
F: =================================
F: [AST]
F: (e)"syntax"          -> Let: Function : show, para = [],  [name: group(analyze)-1]
F: ---------------------------------
F: [Match Stack]
F: None
F: =================================
F: |
F: |
F: |
F: |
F: |  |\ Next Expression
F: |__|
F:
F: ## Resume Info ##
F: nil
F:
```

This is intended since '=' is not registered to the Ast. Let's move to next step.  
 
# 2nd Modification

So, for the next Ast became like:

```
# typed: false
# frozen_string_literal: true

require './lib/sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, ' ')
      )
    }
  }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show])) {
      _SS(
        _S << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2') << E(:e, '"') << E(:e,
';')
      )
    }
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, "\n")
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
```

And the output is:

```
sheep_ast$ rake example3
echo "== Example3: compile =="
== Example3: compile ==
 bundle exec ruby example/protobuf/main.rb
pair = {:_1=>"syntax", :_2=>"=", :_3=>"\"", :_4=>"proto2", :_5=>"\"", :_6=>";", :_namespace=>[], :_raw_line=>"syntax = \"proto2\";\n", :_data=>custom inspect <SheepAst::AnalyzeData object_id = 5960, expr = '";"', stack = [1, 2, 3, 4, 5, 6], stack_symbol = [:_1, :_2, :_3, :_4, :_5, :_6], request_next_data = #<SheepAst::RequestNextData::Next>, file_info = custome inspect <SheepAst::FileInfo object_id = 5940, file = "example/protobuf/example.proto", chunk = nil, line = 0, max_line = 26, index = 8, namespace_stack = [], ast_include = nil, ast_exclude = nil, new_file_validation = true>, raw_line = "syntax = \"proto2\";\n"}
F: StageManager> All the AST stage not found expression. Lazy Abort!
F: exception is observe. detail => #<SheepAst::Exception::NotFound: '"package"'>, bt => ["call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "stage_manager.rb:310", "call_validation.rb:847", "call_validation.rb:847", "analyzer_core.rb:214", "file_manager.rb:71", "file_manager.rb:54", "file_manager.rb:54", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:213", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:134", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:42", "analyzer_core.rb:188", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:41"]
F:
F: ## Tokenizer information start ##
F:
F:
F: ## Analyze information start ##
F: Processing file
F: - example/protobuf/example.proto
F:
F: Tokenized Expression
F: - expr = package
F: - tokenized line = ["package", " ", "tutorial", ";", "\n"]
F: - line no = 3
F: - index = 1
F: - max_line = 26
F:
F: |
F: |
F: |
F: |/
F: =================================
F: always.ignore> tree & Stack
F: =================================
F: [AST]
F: (e)" "               -> NoAction [name: group(analyze)-1]
F: ---------------------------------
F: [Match Stack]
F: None
F: =================================
F: |
F: |
F: |
F: |/
F: =================================
F: default.main> tree & Stack
F: =================================
F: [AST]
F: (e)"syntax"          -> (e)"="               -> (e)"\""              -> (e)"proto2"          -> (e)"\""              -> (e)";"               -> Let: Function : show, para = [],  [name: group(analyze)-1]
F: ---------------------------------
F: [Match Stack]
F: None
F: =================================
F: |
F: |
F: |
F: |/
F: =================================
F: always.continue> tree & Stack
F: =================================
F: [AST]
F: (e)"\n"              -> NoAction [name: group(analyze)-1]
F: ---------------------------------
F: [Match Stack]
F: None
F: =================================
F: |
F: |
F: |
F: |
F: |  |\ Next Expression
F: |__|
F:
F: ## Resume Info ##
F: nil
F:
```

The modification is :

1. Registered 'syntax = 'proto2';' parsing syntax
2. Registered to ignore newline '\n' after the 'default.main' parsed.


To see the output, for this time, 'package' expression in line no = 3 is not found.  
Since there is no registered syntax, this error happened. We need to register so that all the NotFound error is suppressed. In next example, there is no NotFound error.

# 3rd Modification

```
# typed: false
# frozen_string_literal: true

require './lib/sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, ' ')
      )
    }
  }
end

core.config_ast('default.ignore_syntax') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show, {disable: true}])) {
      _SS(
        _S << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2') << E(:e, '"') << E(:e, ';'),
        _S << E(:e, 'package') << E(:any) << E(:e, ';')
      )
    }
  }
end

core.config_ast('default.parse1') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show])) {
      _SS(
        _S << E(:e, 'message') << E(:any) << E(:sc, '{', '}')
      )
    }
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      _SS(
        _S << E(:e, "\n"),
        _S << E(:eof)
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
```

In this modification, following are changed:

#. Changed Ast name.
#. Changed show option to disable since the debug for the Ast is no need.
#. Added parser for 'package ...' syntax.
#. Added message syntax parser.
#. Added redirect action with dry_run option enabled for message syntax parser.
#. Added redirect action with namespace for message syntax parser.
#. Added eof parser.


The output is like:

```

```

To look closer the :show output, it extract corretly message struct. However, message statement is nested. So we need to recursively estimate the chunk of the matched expressions. For next stage it is done.



