# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redcrumbs/version"

Gem::Specification.new do |s|
  s.name        = "redcrumbs"
  s.version     = Redcrumbs::VERSION
  s.authors     = ["John Hope"]
  s.email       = ["john@shiftdock.com"]
  s.homepage    = "https://github.com/JonMidhir/Redcrumbs"
  s.summary     = %q{Fast and unobtrusive activity tracking of ActiveRecord models using DataMapper and Redis}
  s.description = %q{Fast and unobtrusive activity tracking of ActiveRecord models using DataMapper and Redis}

  s.rubyforge_project = "redcrumbs"
  
  s.add_dependency 'data_mapper', '>= 1.2.0'
  s.add_dependency 'redis', '>= 2.2.2'
  s.add_dependency 'dm-redis-adapter', '>= 0.6.2'
  s.add_dependency 'redis-namespace', '>= 1.3.0'
  s.add_dependency 'activerecord', '>= 3.2', '< 5'
  s.add_dependency 'activesupport', '>= 3.2', '< 5'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = s.files.grep(/^spec/)
  s.require_paths = ["lib"]
end
