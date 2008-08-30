Gem::Specification.new do |s|
  s.name = %q{present}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Genki Takiuchi"]
  s.date = %q{2008-08-31}
  s.default_executable = %q{present}
  s.description = %q{Presentation tool for terminal.}
  s.email = %q{genki@s21g.com}
  s.executables = ["present"]
  s.extra_rdoc_files = ["README", "ChangeLog"]
  s.files = ["README", "ChangeLog", "Rakefile", "bin/present", "test/test_helper.rb", "test/present_test.rb", "lib/present", "lib/present/page.rb", "lib/present.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://cocktail-party.rubyforge.org}
  s.rdoc_options = ["--title", "present documentation", "--charset", "utf-8", "--opname", "index.html", "--line-numbers", "--main", "README", "--inline-source", "--exclude", "^(examples|extras)/"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{cocktail-party}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Presentation tool for terminal.}
  s.test_files = ["test/present_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<ncurses>, [">= 0"])
      s.add_runtime_dependency(%q<text>, [">= 0"])
      s.add_runtime_dependency(%q<escape>, [">= 0"])
      s.add_runtime_dependency(%q<redgreen>, [">= 0"])
    else
      s.add_dependency(%q<ncurses>, [">= 0"])
      s.add_dependency(%q<text>, [">= 0"])
      s.add_dependency(%q<escape>, [">= 0"])
      s.add_dependency(%q<redgreen>, [">= 0"])
    end
  else
    s.add_dependency(%q<ncurses>, [">= 0"])
    s.add_dependency(%q<text>, [">= 0"])
    s.add_dependency(%q<escape>, [">= 0"])
    s.add_dependency(%q<redgreen>, [">= 0"])
  end
end
