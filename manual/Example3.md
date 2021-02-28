# sheep_ast example3

In this example, it is tried to create application from scratch. This application is to make list of gpb proto file's Structure and Members by extracting from proto file. The further application from this application is thought widely. So this example explains how to generate file from existing file. This is done by using {SheepAst::LetCompile} module.

# proto file

The analysis target is the proto file from here:\
https://developers.google.com/protocol-buffers/docs/cpptutorial#defining-your-protocol-format

```
syntax = "proto2";

package tutorial;

message Person {
  optional string name = 1;
  optional int32 id = 2;
  optional string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    optional string number = 1;
    optional PhoneType type = 2 [default = HOME];
  }

  repeated PhoneNumber phones = 4;
}

message AddressBook {
  repeated Person people = 1;
}
```

# Skelton Application

At first, let's prepare skelton application. It is like following:

```
# typed: false
# frozen_string_literal: true

require 'sheep_ast'

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
F: exception is observe. detail => #<SheepAst::Exception::NotFound: '"syntax"'>, bt => ["call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "stage_manager.rb:310", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:226", "file_manager.rb:71", "file_manager.rb:54", "file_manager.rb:54", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:225", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:134", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:15", "analyzer_core.rb:192", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:14"]
F:
F: ## Tokenizer information start ##
F:
F:
F: ## Analyze information start ##
F: Processing file
F: - "example/protobuf/example.proto"
F:
F: Tokenized Expression
F: - expr = syntax
F: - tokenized line = ["syntax", " ", "=", " ", "\"", "proto2", "\"", ";", "\n"]
F: - line no = 1
F: - index = 1
F: - max_line = 26
F: - namespacee = []
F: - ast include = nil
F: - ast exclude = nil
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
F: []
F:
F: Exception was occured at analyzer core
F: Not entering pry debug session.
F: Please define SHEEP_DEBUG_PRY for entering pry debug session
```

This is expected since 'syntax' is not registered to the Ast.\
Let's register so that NotFound exception is not happened at first line.\
 
# 1st modification - Clear NotFound error at the first line

It becomes like:

```
# typed: false
# frozen_string_literal: true

require 'sheep_ast'

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      SS(
        S() << E(:e, ' ')
      )
    }
  }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze') {
      SS(
        S() << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2')\
           << E(:e, '"') << E(:e, ';') << A(:let, [:show])
      )
    }
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      SS(
        S() << E(:e, "\n")
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

--- show ---
pair = {:_1=>"syntax", :_2=>"=", :_3=>"\"", :_4=>"proto2", :_5=>"\"", :_6=>";", :_namespace=>[], :_raw_line=>"syntax = \"proto2\";\n", :_data=>custom inspect <SheepAst::AnalyzeData object_id = 6020, expr = '";"', stack = [1, 2, 3, 4, 5, 6], stack_symbol = [:_1, :_2, :_3, :_4, :_5, :_6], request_next_data = #<SheepAst::RequestNextData::Next>, file_info = custome inspect <SheepAst::FileInfo object_id = 6000, file = "example/protobuf/example.proto", chunk = nil, line = 0, max_line = 26, index = 8, namespace_stack = [], ast_include = nil, ast_exclude = nil, new_file_validation = true>, tokenized_line = ["syntax", " ", "=", " ", "\"", "proto2", "\"", ";", "\n"], raw_line = "syntax = \"proto2\";\n"}
--- end  ---

F: StageManager> All the AST stage not found expression. Lazy Abort!
F: exception is observe. detail => #<SheepAst::Exception::NotFound: '"package"'>, bt => ["call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "stage_manager.rb:310", "call_validation.rb:847", "call_validation.rb:847", "analyzer_core.rb:226", "file_manager.rb:71", "file_manager.rb:54", "file_manager.rb:54", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:225", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "analyzer_core.rb:134", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:42", "analyzer_core.rb:192", "call_validation.rb:126", "call_validation.rb:126", "_methods.rb:231", "main.rb:41"]
F:
F: ## Tokenizer information start ##
F:
F:
F: ## Analyze information start ##
F: Processing file
F: - "example/protobuf/example.proto"
F:
F: Tokenized Expression
F: - expr = package
F: - tokenized line = ["package", " ", "tutorial", ";", "\n"]
F: - line no = 3
F: - index = 1
F: - max_line = 26
F: - namespacee = []
F: - ast include = nil
F: - ast exclude = nil
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
F: []
F:
F: Exception was occured at analyzer core
F: Not entering pry debug session.
F: Please define SHEEP_DEBUG_PRY for entering pry debug session
```

The modification is :

1. Registered 'syntax = 'proto2';' parsing syntax.
1. Registered to ignore newline '\n' after the 'default.main' parsed.
1. To see the extract content, registered let :show action.


To see the output, for this time, 'package' expression in line no = 3 is not found.  
We need to register so that all the NotFound error is suppressed. In next example, there is no NotFound error.

# 2nd modification - Clear all the NotFound error

It becomes like:

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
      SS(
        S() << E(:e, ' ')
      )
    }
  }
end

core.config_ast('default.ignore_syntax') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show, {disable: true}])) {
      SS(
        S() << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2') << E(:e, '"') << E(:e, ';'),
        S() << E(:e, 'package') << E(:any) << E(:e, ';')
      )
    }
  }
end

core.config_ast('default.parse1') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show])) {
      SS(
        S() << E(:e, 'message') << E(:any) << E(:sc, '{', '}')
      )
    }
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:na)) {
      SS(
        S() << E(:e, "\n"),
        S() << E(:eof)
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(['example/protobuf/example.proto'])
}
```

In this modification, following are changed:

1. Changed Ast name.
1. Changed show option to disable since the debug for the Ast is no need.
1. Added parser for 'package ...' syntax.
1. Added message syntax parser.
1. Added redirect action with dry_run option enabled for message syntax parser.
1. Added redirect action with namespace for message syntax parser.
1. Added eof parser.


The output is like:

```
sheep_ast$ rake example3
echo "== Example3: compile =="
== Example3: compile ==
 bundle exec ruby example/protobuf/main.rb

--- show ---
pair = {:_1=>"message", :_2=>"Person", :_3=>["{", "\n", "optional", "string", "name", "=", "1", ";", "\n", "optional", "int32", "id", "=", "2", ";", "\n", "optional", "string", "email", "=", "3", ";", "\n", "\n", "enum", "PhoneType", "{", "\n", "MOBILE", "=", "0", ";", "\n", "HOME", "=", "1", ";", "\n", "WORK", "=", "2", ";", "\n", "}", "\n", "\n", "message", "PhoneNumber", "{", "\n", "optional", "string", "number", "=", "1", ";", "\n", "optional", "PhoneType", "type", "=", "2", "[", "default", "=", "HOME", "]", ";", "\n", "}", "\n", "\n", "repeated", "PhoneNumber", "phones", "=", "4", ";", "\n", "}"], :_namespace=>[], :_raw_line=>"}\n", :_data=>custom inspect <SheepAst::AnalyzeData object_id = 6960, expr = '"}"', stack = [10, 11, 12], stack_symbol = [:_1, :_2, :_3], request_next_data = #<SheepAst::RequestNextData::Next>, file_info = custome inspect <SheepAst::FileInfo object_id = 6940, file = "example/protobuf/example.proto", chunk = nil, line = 21, max_line = 26, index = 1, namespace_stack = [], ast_include = nil, ast_exclude = nil, new_file_validation = true>, tokenized_line = ["}", "\n"], raw_line = "}\n"}
--- end  ---


--- show ---
pair = {:_1=>"message", :_2=>"AddressBook", :_3=>["{", "\n", "repeated", "Person", "people", "=", "1", ";", "\n", "}"], :_namespace=>[], :_raw_line=>"}\n", :_data=>custom inspect <SheepAst::AnalyzeData object_id = 6960, expr = '"}"', stack = [10, 11, 12], stack_symbol = [:_1, :_2, :_3], request_next_data = #<SheepAst::RequestNextData::Next>, file_info = custome inspect <SheepAst::FileInfo object_id = 6940, file = "example/protobuf/example.proto", chunk = nil, line = 25, max_line = 26, index = 1, namespace_stack = [], ast_include = nil, ast_exclude = nil, new_file_validation = true>, tokenized_line = ["}", "\n"], raw_line = "}\n"}
--- end  ---
```

To look closer the :show output, it extract corretly message struct. To analyze inside message strings, we need to redirect it to the proper AST again.\
Followings are the reflect it.

# 3rd modification - Parse redirected strings

So script becomes following:

```
# typed: ignore
# frozen_string_literal: true

#rubocop: disable all
def configure(core)
  template1 = 'template_message.erb'
  template2 = 'template_enum.erb'
  action1 = [:compile, template1, { dry_run: false }]
  action2 = [:compile, template2, { dry_run: false }]
  dry1 = false
  dry2 = false

  core.config_tok do |tok|
  end

  core.config_ast('always.ignore') do |_ast, syn|
    syn.within {
      register_syntax('analyze', A(:na)) {
        SS(
          S() << E(:e, ' ')
        )
      }
    }
  end

  core.config_ast('default.ignore_syntax') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        SS(
          S() << E(:e, 'syntax') << E(:e, '=') << E(:e, '"') << E(:e, 'proto2')\
              << E(:e, '"') << E(:e, ';') << A(:let, [:show, disable: true]),
          S() << E(:e, 'package') << E(:any) << E(:e, ';') << A(:let, [:show, disable: true])
        )
      }
    }
  end

  core.config_ast('message.parser') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        S(:branch1) { S() << E(:e, 'optional') << E(:any, repeat: 4)
        S(:branch2) { S() << E(:e, 'repeated') << E(:any, repeat: 4)
        SS(
          S(:branch1) << E(:e, ';') << A(:let, action1),
          S(:branch1) << E(:e, '[') << E(:any, repeat: 4) << E(:e, ';')\
                                    << A(:let, action1),
          S(:branch2) << E(:e, ';') << A(:let, action1),
          S(:branch2) << E(:e, '[') << E(:any, repeat: 4) << E(:e, ';')\
                                    << A(:let, action1)
        )
      }
    }
  end

  core.config_ast('enum.parser') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        SS(
          S() << E(:any, at_head: true) << E(:any, repeat: 2) << E(:e, ';')\
              << A(
                :let,
                action2
              )
        )
      }
    }
  end

  core.config_ast('default.parse1') do |_ast, syn|
    syn.within {
      register_syntax('analyze') {
        SS(
          S() << E(:e, 'message') << E(:any) << E(:sc, '{', '}') \
              << A(:let, [:redirect, :_3, 2..-2, dry_run: dry1, namespace: :_2, ast_include: ['default', 'message']]),
          S() << E(:e, 'enum') << E(:any) << E(:sc, '{', '}') \
              << A(:let, [:redirect, :_3, 2..-2, dry_run: dry2, namespace: :_2, ast_include: ['enum']])
        )
      }
    }
  end

  core.config_ast('always.continue') do |_ast, syn|
    syn.within {
      register_syntax('analyze', A(:na)) {
        SS(
          S() << E(:e, "\n"),
          S() << E(:eof)
        )
      }
    }
  end
end
```

Here we modified:

1. Added message.parser Ast to parse inside message struct
1. Added enum.parser Ast to parse inside enum struct
1. The message scoped matched strings are redirected to default and message domain
1. The enum scoped matched strings are redirected to enum domain

Note that Following S statements uses as variable for `:branch1` and `:branch2` with `S() << ...` respectively.

```
S(:branch1) { S() << E(:e, 'optional') << E(:any, repeat: 4) }
S(:branch2) { S() << E(:e, 'repeated') << E(:any, repeat: 4) }
```

Here `{...}` is assigning value to S(:xxx).  
By this assignment, `S(:xxx)` can be used later for multiple times.  
  
Please execute the script on your environment, you'll see the show output shows message and enum contents are extracted correctly.
Fiinaly we can compile and generate new file from the information. Let's do it.

# 4th modification - compile from template file and parsed information

Script becomes:

```
# typed: false
# frozen_string_literal: true

require 'sheep_ast'

template1 = 'example/protobuf/template_message.erb'
template2 = 'example/protobuf/template_enum.erb'
action1 = [:compile, template1, { dry_run: false }]
action2 = [:compile, template2, { dry_run: false }]
dry1 = false
dry2 = false

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
end

...
```

action1 and action2 are changed to use compile method.

The template file looks like:

```
sheep_ast$ cat example/protobuf/template_message.erb
<%# Output file name => !"example/protobuf/result".txt!  %>
<% ns = namespace.empty? ? '' : namespace + '::'  %>
<%= ns + data[:_3] %> : type = <%= data[:_2] %>, property = <%= data[:_1]  %>
```

```
sheep_ast$ cat example/protobuf/template_enum.erb
<%# Output file name => !"example/protobuf/result".txt!  %>
<% ns = namespace.empty? ? '' : namespace + '::'  %>
<%= ns + data[:_1] %> : type = int, property = enum
sheep_ast$
```

This is typical notation of the erb file.
The only difference is the line number 1. This is sheep_ast original. The `!` enclised strings indicate output file. Double quatation must be added for now.

And the result.txt is

```
sheep_ast$ cat example/protobuf/result.txt
Person::name : type = string, property = optional
Person::id : type = int32, property = optional
Person::email : type = string, property = optional
Person::PhoneType::MOBILE : type = int, property = enum
Person::PhoneType::HOME : type = int, property = enum
Person::PhoneType::WORK : type = int, property = enum
Person::number : type = string, property = optional
Person::type : type = PhoneType, property = optional
Person::phones : type = PhoneNumber, property = repeated
AddressBook::people : type = Person, property = repeated
```

In this example, the compile method is called at the matched timing.
It is also possible to call compile method to {SheepAst::DataStore} object. So, you can store the information to the object by record method and you can use compile method to the object. The compile method uses erb library, so syntax is not changed for both method.







