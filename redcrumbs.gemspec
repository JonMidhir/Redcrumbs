# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redcrumbs/version"

Gem::Specification.new do |s|
  s.name        = "redcrumbs"
  s.version     = Redcrumbs::VERSION
  s.authors     = ["John Hope"]
  s.email       = ["info@midhirrecords.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "redcrumbs"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency 'data_mapper', '>= 1.2.0'
  s.add_dependency 'dm-redis-adapter', '>= 0.6.2'
end
