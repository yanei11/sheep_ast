# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'sheep_ast'

describe 'run-sheep-ast' do
  cur = Dir.pwd
  it 'can run example3' do
    expect(
      system(
        "./out/*.AppImage\
         -r #{cur}/example/protobuf2/configure.rb\
         -o #{cur}/example/protobuf2/\
         -t #{cur}/example/protobuf2/\
         #{cur}/example/protobuf2/example.proto"
      )
    ).to eq true
  end
end
