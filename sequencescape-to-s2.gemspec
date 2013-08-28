# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'sequencescape-to-s2/version'

Gem::Specification.new do |s|
  s.name        = "sequencescape-to-s2"
  s.version     = SequencescapeToS2::VERSION
  s.authors     = ["Loic Le Henaff"]
  s.email       = ["llh1@sanger.ac.uk"]
  s.homepage    = ""
  s.summary     = %q{}
  s.description = %q{}

  s.rubyforge_project = ""

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib", "config"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  s.add_dependency('facets')
  s.add_dependency('virtus')
  s.add_dependency('aequitas')
  s.add_dependency('sequel')

  #development
  s.add_development_dependency('rspec', '~> 2.8.0')
  s.add_development_dependency('yard', '>= 0.7.0')
  s.add_development_dependency('yard-rspec', '0.1')
  s.add_development_dependency('rake')
end
