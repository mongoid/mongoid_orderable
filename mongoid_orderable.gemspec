# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mongoid_orderable/version"

Gem::Specification.new do |s|
  s.name        = "mongoid_orderable"
  s.version     = MongoidOrderable::VERSION
  s.authors     = ["pyromaniac"]
  s.email       = ["kinwizard@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Acts as list mongoid implementation}
  s.description = %q{Gem allows mongoid model behave as orderable list}

  s.rubyforge_project = "mongoid_orderable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_runtime_dependency "mongoid"
end
