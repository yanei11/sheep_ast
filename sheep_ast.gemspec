# rubocop: disable all
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sheep_ast/version"

Gem::Specification.new do |spec|
  spec.name          = "sheep_ast"
  spec.version       = SheepAst::VERSION
  spec.authors       = ["yanei11"]
  spec.email         = ["yanei@outlook.jp"]

  spec.summary       = %q{Toolkit for using AST}
  spec.description   = %q{Toolkit for using AST (abstraction syntax tree) for parsing, code generating, and analysis}
  spec.homepage      = "https://github.com/yanei11/sheep_ast"
  spec.license       = "MIT"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage 
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "sorbet"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-sorbet"
  spec.add_development_dependency "code-scanning-rubocop"
  spec.add_runtime_dependency "sorbet-runtime"
  spec.add_runtime_dependency "rainbow"
  spec.add_runtime_dependency "pry"
  spec.add_runtime_dependency "erb"
end
