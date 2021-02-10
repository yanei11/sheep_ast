# typed: false
# frozen_string_literal: true
# rubocop:disable all

cur = Dir.pwd

class String
  def green; "\e[32m#{self}\e[0m" end
  def magenta; "\e[35m#{self}\e[0m" end
end

def assert_cmd(desc, cmd, expect = true)
  puts
  puts "=== test (#{desc.green}) ==="
  puts "CMD => #{cmd.magenta}"
  res = system(cmd)
  if res != expect
    raise "Failed test."
  end
  puts "=== test ended ==="
  puts
end

assert_cmd('example3',
  "./out/*.AppImage\
   -r #{cur}/example/protobuf2/configure.rb\
   -o #{cur}/example/protobuf2/\
   -t #{cur}/example/protobuf2/\
   #{cur}/example/protobuf2/example.proto"
)

assert_cmd('example2',
  "./out/*.AppImage\
   -r #{cur}/example//keyword_get/main.rb\
   #{cur}/spec/unit/scoped_match_file/test2.cc"
)
