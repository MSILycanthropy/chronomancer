# frozen_string_literal: true

require_relative "lib/chronomancer/version"

Gem::Specification.new do |spec|
  spec.name = "chronomancer"
  spec.version = Chronomancer::VERSION
  spec.authors = ["MSILycanthropy"]
  spec.email = ["ethanmichaelk@gmail.com"]

  spec.summary = "A flexible date sequencing library for Ruby"
  spec.description = "A flexible date sequencing library for Ruby"
  spec.homepage = "https://github.com/MSILycanthropy/chronomancer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(["git", "ls-files", "-z"], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?("bin/", "test/", "spec/", "features/", ".git", ".github", "appveyor", "Gemfile")
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("activesupport", ">= 5.2", "< 9")
end
