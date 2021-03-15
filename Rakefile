# frozen_string_literal: true
# rubocop:disable all

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

cur = Dir.pwd

srb_ignore = ' --ignore /spec --ignore /example'

task 'default' => ['cop', 'tc', 'unit', 'bin']

desc 'Executing rspec, usage => [TESTCASE=xxx_spec.rb:line] rake'
task 'unit' do
  sh "bundle exec rspec #{ENV['TESTCASE']} --fail-fast"
end

desc 'Executing rspec/bin'
task 'bin-appimage' do
  ENV['AppImage'] = '1'
  if Dir['out/*.AppImage'].empty?
    Rake::Task['appimage'].invoke
  end
  sh "ruby spec/bin/*.rb"
end

desc 'Executing rspec/bin'
task 'bin' do
  sh "ruby spec/bin/*.rb"
end

desc 'Executing rubocop'
task 'cop' do
  sh 'rubocop'
end

desc 'erase appimage files'
task 'init-appimage' do
  sh 'rm -rf run-sheep-ast out .Appimage'
end

desc 'sorbet init'
task 'srbinit' => 'init-appimage' do
  sh "bundle exec srb init #{srb_ignore}"
end

desc 'Execute sorbet type check'
task 'tc' => 'init-appimage'do
  sh "bundle exec srb tc #{srb_ignore}"
end

desc 'Execute sorbet type check with auto correct'
task 'tca' => 'init-appimage' do
  sh "bundle exec srb tc -a #{srb_ignore}"
end

desc 'Introduction, Hello world program'
task 'hello' do
  sh "bundle exec ruby example/hello_world/main.rb"
end

desc 'Execute example1 program'
task 'example1' do
  sh 'echo "== Example1: Like Grep program by sheep_ast =="'
  sh "bundle exec ruby example/grep_like/main.rb  'test' spec/unit/scoped_match_file/test1.cc \
      spec/unit/scoped_match_file/test2.cc spec/unit/scoped_match_file/test3.cc"
  sh 'echo "== Grep result =="'
  sh 'grep test spec/unit/scoped_match_file/test1.cc spec/unit/scoped_match_file/test2.cc\
      spec/unit/scoped_match_file/test3.cc --color=auto'
end

desc 'Execute example1 fail version program'
task 'example1_fail' do
  sh "bundle exec ruby example/grep_like/main_fail.rb  'test' spec/unit/scoped_match_file/test1.cc \
      spec/unit/scoped_match_file/test2.cc spec/unit/scoped_match_file/test3.cc"
end

desc 'Execute example2 program'
task 'example2' do
  sh 'echo "== Example2: key word extraction =="'
  sh "bundle exec ruby example/keyword_get/main.rb"
end

desc 'Execute example3 program'
task 'example3' do
  sh 'echo "== Example3: compile =="'
  sh "bundle exec ruby example/protobuf/main.rb"
end

desc 'Execute example3-2 program'
task 'example3-2' do
  sh 'echo "== Example3-2: compile =="'
  sh 'bin/run-sheep-ast -r example/protobuf2/configure.rb -o example/protobuf2/ -t example/protobuf2/ \
      example/protobuf2/example.proto'
end

desc 'Create doc repository'
task 'doc' do
  sh "cd #{ENV['SHEEP_DOC_DIR']}/.. && SHEEP_RV=#{RUBY_VERSION} rake change-version && SHEEP_DIR=#{cur} rake doc"
end

desc 'Push document repository'
task 'pushd' => 'doc' do
  sh "cd #{ENV['SHEEP_DOC_DIR']}/.. && rake push"
end

desc 'Push document repository'
task 'doc-init' do
  sh "cd #{ENV['SHEEP_DOC_DIR']}/.. && rake init"
end

desc 'create appimage'
task 'appimage' => ['init-appimage', 'build'] do
  workdir = 'run-sheep-ast/'
  sh "mkdir -p #{workdir}"
  sh "cp pkg/* #{workdir}"
  sh 'wget -c https://github.com/$(wget -q https://github.com/AppImage/pkg2appimage/releases -O - | grep "pkg2appimage-.*-x86_64.AppImage" | head -n 1 | cut -d \'"\' -f 2)'
  sh 'chmod +x ./pkg2appimage-*.AppImage'
  sh './pkg2appimage-*.AppImage sheep_ast_appimage.yml'
  sh 'rm -rf run-sheep-ast/ .AppDir pkg'
  sh 'rm pkg2appimage-*.AppImage'
end

desc 'change ruby version by rbenv. Specify SHEEP_RV environment parameter for ruby version'
task 'change-version' do
  if !ENV['SHEEP_RV']
    puts 'specify ruby version like 3.0.0 to SHEEP_RV env'
    exit 1
  else
    sh "rbenv local #{ENV['SHEEP_RV']}"
    sh 'gem install bundler'
    sh "bundle update"
    sh "bundle install"
    sh "bundle install"
  end
end

desc 'Before release check test only'
task 'prepare' => %w[init-appimage tc unit bin bin-appimage]

desc 'Before release check'
task 'prepare full' => %w[init-appimage tc unit bin bin-appimage pushd]
