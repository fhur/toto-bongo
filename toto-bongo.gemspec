# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{toto-bongo}
  s.version = "1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Palacio"]
  s.date = %q{2011-3-27}
  s.description = %q{Minimalist blog for your existing app}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
     ".document",
     ".gitignore",
     "LICENSE",
     "README.md",
     "Rakefile",
     "VERSION",
     "lib/ext/ext.rb",
     "lib/toto-bongo.rb",
     "test/articles/2009-12-11-the-dichotomy-of-design.txt",
     "test/autotest.rb",
     "test/templates/about.rhtml",
     "test/templates/archives.rhtml",
     "test/templates/article.rhtml",
     "test/templates/feed.builder",
     "test/templates/index.builder",
     "test/templates/index.rhtml",
     "test/templates/layout.rhtml",
     "test/templates/repo.rhtml",
     "test/test_helper.rb",
     "test/toto_test.rb",
     "toto.gemspec"
  ]
  s.homepage = %q{https://github.com/danpal/toto-bongo}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.test_files = [
    "test/autotest.rb",
    "test/test_helper.rb",
    "test/toto_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<riot>, [">= 0"])
      s.add_runtime_dependency(%q<builder>, [">= 0"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<rdiscount>, [">= 0"])
    else
      s.add_dependency(%q<riot>, [">= 0"])
      s.add_dependency(%q<builder>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<rdiscount>, [">= 0"])
    end
  else
    s.add_dependency(%q<riot>, [">= 0"])
    s.add_dependency(%q<builder>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<rdiscount>, [">= 0"])
  end
end


