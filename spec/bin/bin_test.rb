# typed: ignore
# frozen_string_literal: true
# rubocop:disable all

cur = Dir.pwd

appimage = './out/*.AppImage'
bin = './bin/run-sheep-ast'

env = ENV['AppImage']

if env
  run = appimage
else
  run = bin
end

class String
  def green; "\e[32m#{self}\e[0m" end
  def magenta; "\e[35m#{self}\e[0m" end
end

def assert_cmd(desc, cmd, expect = true, **option)
  puts
  puts "=== test (#{desc.green}) ==="
  puts "CMD => #{cmd.magenta}"

  res = expect

  begin 
    res = system(cmd)
  rescue
    if option['expect_raise']
      raise "Failed test with exception"
    end
  end

  if res != expect
    raise "Failed test."
  end

  puts "=== test ended ==="
  puts
end

assert_cmd('hello',
          "bundle exec ruby #{cur}/example/hello_world/main.rb"
)


assert_cmd('example1',
          "bundle exec ruby #{cur}/example/grep_like/main.rb 'test'\
            spec/unit/scoped_match_file/test1.cc\
            spec/unit/scoped_match_file/test2.cc\
            spec/unit/scoped_match_file/test3.cc"
)

assert_cmd('example1_fail',
          "bundle exec ruby #{cur}/example/grep_like/main_fail.rb 'test'\
            spec/unit/scoped_match_file/test1.cc\
            spec/unit/scoped_match_file/test2.cc\
            spec/unit/scoped_match_file/test3.cc",
            false
)

assert_cmd('example2',
  "#{run}\
   -r #{cur}/example/keyword_get/main.rb\
   #{cur}/spec/unit/scoped_match_file/test2.cc"
)

assert_cmd('example3',
  "#{run}\
   -r #{cur}/example/protobuf2/configure.rb\
   -o #{cur}/example/protobuf2/\
   -t #{cur}/example/protobuf2/\
   #{cur}/example/protobuf2/example.proto"
)

assert_cmd('example4',
  "#{run}\
   -r #{cur}/example/multi_condition/configure.rb\
   #{cur}/example/multi_condition/test.txt"
)
