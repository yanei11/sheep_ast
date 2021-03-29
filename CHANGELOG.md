# Change Log
All notable changes to this project will be documented in this file.

## [0.6.0] - 2020-03-22
### Added
- Check at tokenizer to input strings when last word is specific word (default = space)
- EOL validation; If the input is continued after an action is called, then break the analyze
- To disable/enable to call action
- Analyze functin returns AnalyzeCoreReturn object. It contains `result`, `eol`, `next_command` fields

### Breaking Change
- << operator returns boolean. It returned AnalyzerCore object before

## [0.5.0] - 2020-02-28
### Added
- API for AST node to walk for revert direction is added to analyzer core
- Syntax improvement to introduce SS(...) and S(...) function
- Example4 is added

### Breaking Change
- `_SS` and `_S` function is now deprecated function. Will be removed in major release

## [0.4.1] - 2020-02-05
### Added
- Added executable file `bin/run-sheep-ast`

## [0.4.0] - 2020-01-14
### Added
- Include API to Let object to handle include another files

### Changed
- Bugfix [Not open Issue] : Condition Match unexpectedly push matched strings to matched stack at the condition match ended

## [0.3.0] - 2020-01-07
### Added
- Compile API to Let object
- Performance improvement
- Example3
- Multiple condition to some match
- repeat option
- various redirect option
- API documentation

### Changed
- Breaking change: directory structure changed.

## [0.2.1] - 2020-12-16
### Added
- DataStore object can handle multiple value tags
- Matched expression can be edit at the matched timing by extract: x..y
- E(:any) expression is added

### Changed
- NEQ usage changed

## [0.2.0] - 2020-12-15
### Added
- Added NEQ syntax for supporting multiple Action shared syntax chain

### Changed
- Moved Gemfile dependency to gemspec

## [0.1.2] - 2020-12-12
### Removed
- Some deprecated syntax API are removed

## [0.1.0] - 2020-12-12
### Added
- Initial release
