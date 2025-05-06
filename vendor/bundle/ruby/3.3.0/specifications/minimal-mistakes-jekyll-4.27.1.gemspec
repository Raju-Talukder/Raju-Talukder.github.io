# -*- encoding: utf-8 -*-
# stub: minimal-mistakes-jekyll 4.27.1 ruby lib

Gem::Specification.new do |s|
  s.name = "minimal-mistakes-jekyll".freeze
  s.version = "4.27.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "plugin_type" => "theme" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Rose".freeze, "iBug".freeze]
  s.date = "2025-05-02"
  s.homepage = "https://github.com/mmistakes/minimal-mistakes".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.20".freeze
  s.summary = "A flexible two-column Jekyll theme.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<jekyll>.freeze, [">= 3.7".freeze, "< 5.0".freeze])
  s.add_runtime_dependency(%q<jekyll-paginate>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<jekyll-sitemap>.freeze, ["~> 1.3".freeze])
  s.add_runtime_dependency(%q<jekyll-gist>.freeze, ["~> 1.5".freeze])
  s.add_runtime_dependency(%q<jekyll-feed>.freeze, ["~> 0.1".freeze])
  s.add_runtime_dependency(%q<jekyll-include-cache>.freeze, ["~> 0.1".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3".freeze])
end
