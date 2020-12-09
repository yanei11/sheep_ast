# sheep_ast example1

This is the sheep_ast example. This works as Quick start guide. The example1 is at `./example/grep_like/main.rb` from the root directory of sheep_ast repository. The exampe1 is application like linux grep command. To execute example program, please do like:

```
sheep_ast$ make example1
```

After executing the command, it should be seen same output as grep command result.
In the following, how to construct the application is shown step by step. Please see follwoing with example code and example test file.

Followings are the test file. They are cpp sntax code.

- spec/scoped_match_file/test1.cc
- spec/scoped_match_file/test2.cc
- spec/scoped_match_file/test3.cc

# Source Code

The example overall source code is following:

```
# typed: false
# frozen_string_literal: true

require './lib/analyzer_core'
require 'rainbow/refinement'

using Rainbow

input_expr = ARGV[0]
input_files = ARGV[1..-1]

core = Sheep::AnalyzerCore.new

core.config_tok do |tok|
  tok.add_token tok.cmp('#', 'include')
  tok.add_token tok.cmp('/', '/')
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:grep], [:show, { disable: true }], [:debug])) {
      _SS(
        _S << E(:encr, input_expr, "\n")
      )
    }
  }

  syn.action.within {
    def grep(key, datastore, **options)
      str = "#{@data.file_info.file}:".blue
      str += @data.raw_line.chop.to_s
      puts str
    end
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('continue', A(:na)) {
      _SS(
        _S << any
      )
    }
  }
end

core.report(raise: false) {
  core.analyze_file(input_files)
}
```

# Package include

Firstly, you need to include sheep_ast package.
It is done by

```
require './lib/analyzer_core'
```

# AnalyzerCore obect

The analyzer_core object is designed to aggregate the external interfaces.
So, you should create the object.

```
core = Sheep::AnalyzerCore.new
```

# Tokenize

Before inputing expression to the AST, you have chance to combine the expression for simplifying subsequent AST process. In this example, '#' and 'include' strings are combined to one string '#include'. And also '/' and '/' is combined to '//' for the simplifying handling cpp comment.
It is done by:

```
core.config_tok do |tok|
  tok.add_token tok.cmp('#', 'include')
  tok.add_token tok.cmp('/', '/')
end
```

Note that in this example, the above tokenize is not really necessary. It is just for the usae about tokenize process.

# Register AST to multiple stages

Following code block is the AST registrations.

```
core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:grep], [:show, { disable: true }], [:debug])) {
      _SS(
        _S << E(:encr, input_expr, "\n")
      )
    }
  }

  syn.action.within {
    def grep(key, datastore, **options)
      str = "#{@data.file_info.file}:".blue
      str += @data.raw_line.chop.to_s
      puts str
    end
  }
end

core.config_ast('always.continue') do |_ast, syn|
  syn.within {
    register_syntax('continue', A(:na)) {
      _SS(
        _S << any
      )
    }
  }
end

```

The meaning of syntax of the above codeblock is following:

## 1st code block

Ast name is constucted by two part; domain and name.  The `default` is special domain. The default domain is called initially. It works as entry point. So, the none `default` domain will not be called initially and it will be called when user includes the Ast. This related to the recursive estimation of target strings and also related to namespace. In short, user can specify domain to include or exclude the next recursion process. But in this example, this function is not needed. This topic is shown by other example.
The `always` domain has also special meaning. It is always called no matter user tries to exclude. It is always called.

## 2nd code block

`register_syntax` is used to register name, action, match order. This is structure that when match is hit, then the action is called. In this case, :encr means encrosed_regex match. It matches input_expr for the start and end by "\n". It means like, if string matches to regex input_expr is came, and after that "\n" string is came, then :let object's :grep, :show, :debug function are called accordingly. The :show and :debug are the pre-made API function which is defined in let_xxx.rb files. But :grep function is user defined function and it is defined in the:

```
  syn.action.within {
    def grep(key, datastore, **options)
      str = "#{@data.file_info.file}:".blue
      str += @data.raw_line.chop.to_s
      puts str
    end
  }
```

So, to see the signiture of the function, you find key, datastore, options are passed from the framework. But in this grep application, it is no need to use key and datastore, so they are not used inside the function.
To see what kind of information passed from the framework, you can utilise :show function. It is kind of debug function to inspect what the passed data is. If you edit :disable => false, then you will see them. Please check it and you can see beter understanding about framework.


## 3rd code block

The Ast has domain `always` so it is called anytime. And action :na = NotAction is registered. It does not do specific action. The match is `any`. The syntax alias `any` is introduced in the syntax_alias.rb. In that file, you will see `any` is `[:r. '.*']`, and it means it is regex match and the match expression is '.*' which matches any string. That is why it is `any`.
The expression is matched by AST of registered order. So, in this case, expression is processed by `default.main` and by `always.continue`.
Strategy of finding expression in sheep_ast is to evaluate all the Ast in registered ordere, and if they could not match expression, then raise `NotFound` exception. If you execute `make example1_fail`, then you will see the sheep_ast sends `NotFound error`. The failed version. this code block is missing. Since this block matches any expression, so NotFound error never occurs.


# Feed input files to the framework

Final code block is this:

```
core.report(raise: false) {
  core.analyze_file(input_files)
}
```

It input files to analyze. The files are processed accordingly.
`core.report` catches exception and prins debug data if it got exception. If raise is true, core.report sends another exception.
