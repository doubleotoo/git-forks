module GitForks
  VERSION = "0.0.1"

  # The root path for GitForks source
  ROOT = File.expand_path(File.dirname(__FILE__))

  ['autoload', 'globals'].each do |file|
    require File.join(GitForks::ROOT, 'git_forks', file)
  end
end # GitForks
