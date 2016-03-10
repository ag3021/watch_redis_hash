# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'watch_redis_hash/version'

Gem::Specification.new do |spec|
  spec.name          = "watch_redis_hash"
  spec.version       = WatchRedisHash::VERSION
  spec.authors       = ["Andy Ganchrow"]
  spec.email         = ["andy@ganchrow.com"]

  spec.summary       = %q{Watches Ruby Hash and dumps to redis hash on set}
  spec.description   = %q{Watches Ruby Hash and dumps to redis hash on set}
  spec.homepage      = "http://github.com/ag3021/watch_redis_hash"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|bin)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'yajl-ruby', '~> 1.2'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
