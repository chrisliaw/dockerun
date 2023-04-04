# frozen_string_literal: true

require_relative "lib/dockerun/version"

Gem::Specification.new do |spec|
  spec.name          = "dockerun"
  spec.version       = Dockerun::VERSION
  spec.authors       = ["Ian"]
  spec.email         = ["cameronian0@protonmail.com"]

  spec.summary       = ""
  spec.description   = ""
  spec.homepage      = ""
  spec.required_ruby_version = ">= 2.4.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  #spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'toolrack' #, '> 0.19.1'
  spec.add_dependency 'teLogger' #, '> 0.2.0'

  spec.add_dependency 'tty-command' #, "> 0.10.1"
  spec.add_dependency 'tty-option' #, "> 0.2.0"
  spec.add_dependency 'colorize'

  spec.add_dependency 'docker-cli' #, ">= 0.1.2"

  spec.add_development_dependency 'devops_assist'

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
