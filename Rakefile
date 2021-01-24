# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task 'default' => 'check'

desc 'Executing rspec, usage => [TESTCASE=xxx_spec.rb:line] rake'
task 'check' do
  sh "#{ENV['RBENV_COM']} bundle exec rspec #{ENV['TESTCASE']}  --fail-fast"
end

desc 'Executing all rspec, usage => [TESTCASE=xxx_spec.rb:line] rake'
task 'allcheck' do
  sh "#{ENV['RBENV_COM']} bundle exec rspec #{ENV['TESTCASE']}"
end

desc 'Making Yardoc to the SHEEP_DOC_DIR directory.'
task 'doc' do
  sh "rm -rf  #{ENV['SHEEP_DOC_DIR']}"
  sh "#{ENV['RBENV_COM']} bundle exec yardoc -m markdown --plugin sorbet -o #{ENV['SHEEP_DOC_DIR']} - README.md CHANGELOG.md \
      INSTALL.md manual/*"
end

desc 'sorbet init'
task 'srbinit' do
  sh "#{ENV['RBENV_COM']} bundle exec srb init --ignore /spec"
end

desc 'Execute sorbet type check'
task 'tc' do
  sh "#{ENV['RBENV_COM']} bundle exec srb tc --ignore /spec --ignore /example "
end

desc 'Execute sorbet type check with auto correct'
task 'tca' do
  sh "#{ENV['RBENV_COM']} bundle exec srb tc -a --ignore=/spec"
end

desc 'Introduction, Hello world program'
task 'hello' do
  sh "#{ENV['RBENV_COM']} bundle exec ruby example/hello_world/main.rb"
end

desc 'Execute example1 program'
task 'example1' do
  sh 'echo "== Example1: Like Grep program by sheep_ast =="'
  sh "#{ENV['RBENV_COM']} bundle exec ruby example/grep_like/main.rb  'test' spec/scoped_match_file/test1.cc \
      spec/scoped_match_file/test2.cc spec/scoped_match_file/test3.cc"
  sh 'echo "== Grep result =="'
  sh 'grep test spec/scoped_match_file/test1.cc spec/scoped_match_file/test2.cc\
      spec/scoped_match_file/test3.cc --color=auto'
end

desc 'Execute example1 fail version program'
task 'example1_fail' do
  sh "#{ENV['RBENV_COM']} bundle exec ruby example/grep_like/main_fail.rb  'test' spec/scoped_match_file/test1.cc \
      spec/scoped_match_file/test2.cc spec/scoped_match_file/test3.cc"
end

desc 'Execute example2 program'
task 'example2' do
  sh 'echo "== Example2: key word extraction =="'
  sh "#{ENV['RBENV_COM']} bundle exec ruby example/keyword_get/main.rb"
end

desc 'Execute example3 program'
task 'example3' do
  sh 'echo "== Example3: compile =="'
  sh "#{ENV['RBENV_COM']} bundle exec ruby example/protobuf/main.rb"
end

desc 'Push document repository'
task 'pushd' => 'doc' do
  sh "cd #{ENV['SHEEP_DOC_DIR']}/.. && make push"
end

desc 'Before release check'
task 'prepare' => %w[check tc hello example1 example1_fail example2 pushd]
