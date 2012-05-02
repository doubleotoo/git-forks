$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/git_forks/version', __FILE__)

Gem::Specification.new do |s|
  s.name     = "git-forks"
  s.version  = "0.0.4"
  s.version  = GitForks::VERSION::STRING.dup
  s.date     = Time.now.strftime('%F')
  s.summary  = "gets info about a GitHub project's forks"
  s.homepage = "http://github.com/doubleotoo/git-forks"
  s.email    = "doubleotoo@gmail.com"
  s.authors  = ["Justin Too"]

  s.files    = %w( LICENSE )
  s.files    += Dir.glob("lib/**/*")
  s.files    += Dir.glob("bin/**/*")
  s.require_paths = %w[ lib ]

  s.executables = %w( git-forks )
  s.description = "git-forks gets info about a GitHub project's forks."

  s.add_runtime_dependency 'json'
  s.add_runtime_dependency 'launchy'
  s.add_runtime_dependency 'octokit', '= 0.6.5'
end
