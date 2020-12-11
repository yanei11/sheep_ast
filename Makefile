all: check

# Running specific test case
check:
	bundler exec rspec ${TESTCASE} --fail-fast

# Make Yard documentation
doc:
	bundle exec yardoc -m markdown --plugin sorbet -o ${SHEEP_DOC_DIR} - README.md INSTALL.md example/grep_like/Example1.md example/keyword_get/Example2.md

# sheep_ast uses sorbet for static type checing. This command is for it at the init.
srbinit:
	bundler exec srb init --ignore=/spec

# sheep_ast uses sorbet for static type checing. This command is for it.
tc:
	bundler exec srb tc --ignore=/spec

# sheep_ast uses sorbet for static type checing. This command is for it and auto fixing.
tca:
	bundler exec srb tc -a --ignore=/spec

example1:
	echo "== Example1: Like Grep program by sheep_ast =="
	bundler exec ruby example/grep_like/main.rb  'test' spec/scoped_match_file/test1.cc spec/scoped_match_file/test2.cc spec/scoped_match_file/test3.cc
	echo "== Grep result =="
	grep test spec/scoped_match_file/* --color=auto

example1_fail:
	bundler exec ruby example/grep_like/main_fail.rb  'test' spec/scoped_match_file/test1.cc spec/scoped_match_file/test2.cc spec/scoped_match_file/test3.cc
	echo "== Grep result =="

example2:
	echo "== Example2: key word extraction =="
	bundler exec ruby example/keyword_get/main.rb
