Gem::Specification.new do |s|
  s.name              = "ost"
  s.version           = "0.1.5"
  s.summary           = "Redis based queues and workers."
  s.description       = "Ost lets you manage queues and workers with Redis."
  s.authors           = ["Michel Martens"]
  s.email             = ["michel@soveran.com"]
  s.homepage          = "http://github.com/soveran/ost"

  s.files = Dir[
    "LICENSE",
    "README.md",
    "Rakefile",
    "lib/**/*.rb",
    "*.gemspec",
    "test/*.*"
  ]

  s.add_dependency "nido", "~> 0.0.1"
  s.add_dependency "redic", "~> 1.0.1"
  s.add_development_dependency "cutest", "~> 1.0"
end
