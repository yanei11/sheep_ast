# API spec

In this file, external interface for sheep_ast user is written.
Listed APIs are currenly supported.


# Framework

## class AnalyzerCore

This class aggregate user interface.

### config_tok

Syntax:

```
core.config_tok do |tok|
  # ...
end
```

- tok : class Tokenizer

Configure tokenizer instance.

### config_sst

Syntax:
```
core.config_ast do |ast, syn, mf, af|
  # ...
end
```

- ast :  instance of AstManager
- syn :  instance of Syntax
- mf  :  instance of MatchFactory
- af  :  instance of ActionFactory

mf and af arguments are not used now, since syn has MatchFactory and ActonFactory instance.

### analyze_file

Syntax:
```
analyze_file(files)
```

- files : array of file paths to analyze

Analyze files by given tokenizer, Ast objects.

### let

returns Sheep_Ast::Let class

Syntax:
```
let
```

### \<\<

Syntax:
```
core << 'Hello World' << '__sheep_oef__'
```

Used to input raw strings to analyze.
possible to invoke eof validation by input `'__sheep_eof__'`.

### report

Syntax:
```
def report(logs = :pfatal, **options)
  yield
  #...
end
```

- logs [:pfatal] : symbol of log function dump to use..
- options
  - raise => true/false/nil [default = nil] : raise again after catch exception

Catch exception and dump debug log when inside block cause exception.

### dump

Syntax:
```
dump(logs = :pfatal)
```

- logs [:pfatal] : symbol of log function dump to use.

## class Tokenizer

This class use to tune Tokenize behavior

### cmb

combine strings. alias method to cmp

### cmp

compare expressions and combine expresions if matches given expression

```
cmp(*args)
```

args :  String and Regex expression. If args expression matches given expression, framework combine expression.  
  

To use with add_token is expected.

### add_token

Adding token rule.

```
add_token(blk, token = nil, **options)
```

- blk : cmb function is given
- token [nil] : Convert string expression if blk matches expression
- options
  - none

Usage:
```
tok.add_token tok.cmb(expr1, expr2, ...) token
```
If given strings from framework matches 'expr1' 'expr2' '...' then replace them to specified token. If token = nil, then 'expr1expr2expr3' will be used for token.

### use_split_rule

Use basic tokenize by `split`.  
Initially given expression is tokenized by ruby split function.  
This funtion is useful when user input well formatted data that has certain separator like space. It becomes easy for subsequent combine process in certain case.

```
use_split_rule(&blk)
```

- blk : Return String or Regex expression

Usage:

To use default separator
```
buf, _max_line = tok << 'Hello, sheep_ast world'
p buf
# Default base tokenizer : [["Hello", ",", " ", "world", ".", " ", "Now", " ", "2020", "/", "12", "/", "14", " ", "1", ":", "43"]]
tok.use_split_rule { ' ' }
p buf
# Split base tokenizer : [["Hello,", "world.", "Now", "2020/12/14", "1:43"]]
```

## class Syntax

### E

Expression. Returns Match instance which tries to match expression.  
Please see register_syntax

Syntax:
```
E(kind, *para, **kwargs)
```

- kind   : Symbol to specify what kind of Match is spawned. (e.g., :e, :r, :sc, etc. Please see below Match section)
- para   : Variadic parameters are depends on kind of match
- kwargs : Variadic options. Options are depends on match


### _S

Syntax. Returns array of Expressions and Action.
Please see register_syntax

Syntax:
```
_S(*para, **kwargs)
```

- para
  - currently, not used
- kwargs
  - currently, not used


### _SS

Sntaxs. Returns array of Syntax.
Please see register_syntax


Syntax:
```
_S(*para, **kwargs)
```

- para
  - _S result.
- kwargs
  - currently, not used

### register_syntax

Regsiter Ast element to the Ast object.

Syntax:
```
register_syntax(name, action = nil, &blk)
```

- name        : name of Ast element. Used for debug print
- ation[nil]  : Nil is acceptable when blk does not contain Action element. All the Ast elements must have Action at the end if this is nil. If not nil, Action will be added all the Ast elements.
- blk         : result of _SS or _S


Usage:  
Please see example for usage.


# Match

## Match Kind

kind of matches and APIs are below:

### exact match

if given expression matches to 'expr', Ast current point moves to next point.

Usage:
```
E(:e, 'expr', [ :tag_symbol, { optons } ] )
```

### regex match

if given expression matches to regex 'regex_expr', Ast current point moves to next point.

Usage:
```
E(:r, 'regex_expr', [ :tag_symbol, { optons } ] )
```

### scoped match

If given expression matches to 'start_expr', internal counter is incremented, if given expression matches to 'end_expr', internal counter is decremented. If internal counter becomes zero, Ast current point moves to next point.

Usage:
```
E(:sc, 'start_expr', 'end_expr', [ :tag_symbol, { optons } ] )
```

Options:
```
regex_end => true/false [nil]  : end_expr is used as regex to match given expression.
```

### enclosed match

If given expression matches to 'start_expr', and if given expression matches to 'end_expr', Ast current point moves to next point. In contrast to scoped match, enclosed match returns immediately if given expression matches to 'end_expr'.

Usage:
```
E(:sc, 'start_expr', 'end_expr', [ :tag_symbol, { optons } ] )
```

Options:
```
regex_end => true/false [nil]  : end_expr is used as regex to match given expression.
```

### scoped regex match

TBD

### enclosed regex match


TBD


# Action

TBD












