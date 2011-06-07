# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "couch_record/version"

Gem::Specification.new do |s|
  s.name        = "couch_record"
  s.version     = CouchRecord::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Dustin Byrn"]
  s.email       = [""]
  s.homepage    = ""
  s.summary     = %q{A high performance CouchRest ORM for ActiveModel}
  s.description = %q{}

  s.rubyforge_project = "couch_record"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activemodel"
  s.add_dependency "couchrest"

  s.add_development_dependency(%q<rspec>)
end
