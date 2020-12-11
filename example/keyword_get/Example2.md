# sheep_ast example2

This is the sheep_ast example2. This works as Quick start guide. The example2 is at `./example/keyword_get/main.rb` from the root directory of sheep_ast repository. The exampe2 application extracts certain keyword from the cpp file. The application can execute by following.

```
sheep_ast$ rake example2
```

Followings are the test file. It is cpp sntax code.

- spec/scoped_match_file/test2.cc

# Source Code

The example overall source code is following:

```
# typed: false
# frozen_string_literal: true

require './lib/analyzer_core'
require 'rainbow/refinement'

using Rainbow

core = SheepAst::AnalyzerCore.new

core.config_tok do |tok|
  tok.add_token tok.cmp('#', 'include')
  tok.add_token tok.cmp('/', '/')
end

core.config_ast('always.ignore') do |_ast, syn|
  syn.within {
    register_syntax('ignore', A(:na)) {
      _SS(
        _S << space,
        _S << E(:sc, '//', "\n")
      )
    }
  }
end

core.config_ast('default.main') do |_ast, syn|
  syn.within {
    register_syntax('analyze', A(:let, [:show, { disable: true }], [:debug])) {
      _SS(
        _S << E(:e, '#include') << E(:enc, '<', '>'),
        _S << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}')
      )
    }
    register_syntax(
      'analyze',
      A(:let, [:redirect, :test, 1..-2, { namespace: :_2 }], [:show, { disable: true }], [:debug])
    ) {
      _SS(
        _S << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}', :test)
      )
    }
    register_syntax(
      'analyze',
      A(:let,
        [:record_kv_by_id, :ns_test_H, :_2, :_3, { namespace: true }],
        [:show, { disable: true }],
        [:debug])
      ) {
      _SS(
        _S << E(:e, 'class') << E(:r, '.*') << E(:sc, '{', '}') << E(:e, ';')
      )
    }
  }
end

core.config_ast('always.ignore2') do |_ast, syn|
  syn.within {
    register_syntax('ignore', A(:na)) {
      _SS(
        _S << crlf,
        _S << lf,
        _S << eof
      )
    }
  }
end

core.report(raise: true) {
  core.analyze_file(['spec/scoped_match_file/test2.cc'])
}
p core.data_store.value(:ns_test_H)
```

Explanation given in example1 is skipped.

# Chain of match and action

You will see the following Ast registration have multiple `E(...)`. The `_S` can have multiple `E(...)`.

```
        _S << E(:e, 'int') << E(:e, 'main') << E(:enc, '(', ')') << E(:sc, '{', '}')
```
For example this statement means that, target strings that has 'int', nextly 'main', nextly enclosed block from '(' to ')', and such strings should be passed to the `:let` action. The action calls data to `:redirect`, `show`, and `debug` functions.

# Tag symbol

The following syntax has `_2` or `_3`.
It is called tag symbol. It means which matched expression will be used in the action. 

```
    register_syntax(
      'analyze',
      A(:let,
        [:record_kv_by_id, :ns_test_H, :_2, :_3, { namespace: true }],
        [:show, { disable: true }],
        [:debug])
      ) {
      _SS(
        _S << E(:e, 'class') << E(:r, '.*') << E(:sc, '{', '}') << E(:e, ';')
      )
    }
```

The symbol `_2` and `_3` are used for the function `:record_kv_by_id`. It stores key, value pair which are specified tag `_2`, `_3` and it stores to `ns_test_H` specified hash in the datastore object. The tags are corresonds to matched expression of `E(:e, 'class')` and `E(:r, '.*')`. The tags are given by framework. But the tag also can be specified manually like `E(:sc, '{', '}', :test)`.


# Let and redirect function

Let object has function to pass data to multiple functions defined inside Let object. Following syntax's Let calls `:redirect` function, and it is important function in the sheep_ast framework.

```
    register_syntax(
      'analyze',
      A(:let, [:redirect, :test, 1..-2, { namespace: :_2 }], [:show, { disable: true }], [:debug])
    ) {
      _SS(
        _S << E(:e, 'namespace') << E(:r, '.*') << E(:sc, '{', '}', :test)
      )
    }
```

The redirect function make specified data to re-input Ast stages, but it can specify which Ast should process also it can put namespace by tag symbol. Please see redirect yard document or `spec/` test case more detailed. The above syntax matches like:
```
namespace example {
 someprocess();
 someprocess2();
}
```

And redirect function put namespace expression matched `E(:r, '.*')`at tag `_2`, and redirect data specified by :test symbol and range 1..-2 to Ast stages again.
In this case, redirect data will be `\n  someprocess();\n  someprocess2();\n`, and namespace will be `example`
`:redirect` function has options `ast_include` and `ast_exclude` and they can use to specify which Ast can use to process of redirected data.
If you execute this example, you can see the result data has namespace.

# crlf, lf

The last syntax registration has crlf, lf, eof handling.
It prevents NotFound exception by those input.

# eof validation

sheep_ast input special expression `__sheep_eof__`.
It is input after end of process of given file. The eof will never be input in case that core get expression by like `core << 'abc'` (sheep_ast has interface to feed just string as well as input by file path. Please see spec/ testcases)
The eof has important role. It kicks eof validation.
eof validationn is to validate Ast process is finished at the eof. sheep_ast raise error when Ast process is in progress at the timing eof is input.
User can detect bug by this validation. If user wants to use the validatoin in the way of inputing string, user should do like 'core << 'abc' << `__sheep_eof__`

# Summary

In this example, sheep_ast capability to handle how matched expression is handled by tag symbol.
It is also explaind how matched symbol is re-estimated by Let object and redirect function.

